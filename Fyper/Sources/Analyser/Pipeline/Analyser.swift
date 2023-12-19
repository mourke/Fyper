//
//  Analyser.swift
//  Fyper
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import Shared

/// Analyses the code and returns a calling graph of all classes that need to be injected.
struct Analyser {

	let logger: Logger

	/// Parsed file structures obtained from the *Parser* stage.
	let fileStructures: [FileStructure]

	func analyse() -> Analysis {
		var components: [Component] = []
		var allImports: [ImportPathComponentListSyntax] = []

		for (filePath, abstractSyntaxTree) in fileStructures {
			// @mbourke: For simplicity, import everything every file imports to the generated file
			// so there can be no missing typenames.
			let imports = findImportDeclarations(syntax: abstractSyntaxTree)
			logger.log("Looking for Components in \(filePath)...", kind: .debug)
			let componentDeclarations = findComponentDeclarations(syntax: abstractSyntaxTree)
			logger.log("Found \(componentDeclarations.count) Component(s).", kind: .debug)

			for (macro, dataStructure) in componentDeclarations {
				logger.log("Extracting metadata from \(dataStructure.identifier.text)...", kind: .debug)
				var type: TypeSyntaxProtocol = IdentifierTypeSyntax(name: dataStructure.identifier)
				var (exposedAs, isPublic, isSingleton) = extractMetadata(from: macro)

				for initializer in findInitializers(in: dataStructure) {
					let isOptional = initializer.optionalMark?.tokenKind == .postfixQuestionMark

					if isOptional {
						type = OptionalTypeSyntax(wrappedType: type)
						exposedAs = exposedAs.map({OptionalTypeSyntax(wrappedType: $0)})
					}

					let component = Component(
						type: type,
						exposedAs: exposedAs ?? type,
						arguments: separateParameterList(in: initializer),
						isPublic: isPublic,
						isSingleton: isSingleton
					)

					components.append(component)
				}
			}

			// @mbourke: Only add imports if the data structures inside the file participate in
			// dependency injection.
			if !componentDeclarations.isEmpty {
				for importStatement in imports {
					let cleanedStatement = ImportPathComponentListSyntax {
						for pathComponent in importStatement.path {
							ImportPathComponentSyntax(name: pathComponent.name)
						}
					}

					if !allImports.contains(where: {$0.description.lowercased() == cleanedStatement.description.lowercased()}) {
						allImports.append(cleanedStatement)
					}
				}
			}
		}

		return Analysis(
			components: components,
			imports: allImports.sorted(by: {$0.description.lowercased() < $1.description.lowercased()})
		)
	}

	private func findImportDeclarations(syntax: SyntaxProtocol) -> [ImportDeclSyntax] {
		let children = syntax.children(viewMode: .fixedUp)

		guard let importDecl = syntax.as(ImportDeclSyntax.self) else {
			return children.flatMap(findImportDeclarations(syntax:))
		}

		return [importDecl]
	}

	// MARK: - Searching for Components

	private func findComponentDeclarations(syntax: SyntaxProtocol) -> [(AttributeSyntax, DataStructureDeclSyntaxProtocol)] {
		let children = syntax.children(viewMode: .fixedUp)

		guard syntax.kind == .classDecl ||
				syntax.kind == .structDecl ||
				syntax.kind == .actorDecl
		else {
			return children.flatMap(findComponentDeclarations(syntax:))
		}

		let dataStructure: DataStructureDeclSyntaxProtocol = (syntax.as(ClassDeclSyntax.self) ?? syntax.as(StructDeclSyntax.self)) ?? syntax.cast(ActorDeclSyntax.self)
		
		guard let macro = dataStructure.attributes.compactMap(componentMacro(from:)).first else {
			return []
		}

		return [(macro, dataStructure)]
	}

    private func componentMacro(from initialiserAttribute: AttributeListSyntax.Element) -> AttributeSyntax? {
        guard
            case let .attribute(syntax) = initialiserAttribute
        else { return nil }

        let attributeName = syntax.attributeName.cast(IdentifierTypeSyntax.self).name.text
		let isComponentMacro = attributeName == Constants.Reusable || attributeName == Constants.Singleton

		return isComponentMacro ? syntax : nil
    }

	private func extractMetadata(from syntax: AttributeSyntax) -> (exposedAs: TypeSyntaxProtocol?, isPublic: Bool, isSingleton: Bool) {
        let attributeName = syntax.attributeName.cast(IdentifierTypeSyntax.self).name.text
		let isSingleton = attributeName == Constants.Singleton
		var exposedAs: IdentifierTypeSyntax?
		var isPublic = false

        if case let .argumentList(arguments) = syntax.arguments {
			for argument in arguments {
				switch argument.label?.text {
				case Constants.ExposeAs:
                    let identifier = argument.expression.as(DeclReferenceExprSyntax.self)?.baseName
					exposedAs = identifier.map({IdentifierTypeSyntax(name: $0)}) // @mbourke: exposedAs will always be a simple type as inforced by the macro
				case Constants.Scope:
                    let identifier = argument.expression.cast(MemberAccessExprSyntax.self).declName.baseName
					isPublic = identifier.text == String(describing: ComponentScope.public)
				default:
					fatalError()
				}
			}
		}

		return (exposedAs, isPublic, isSingleton)
	}

	private func isDependencyIgnored(from initialiserAttribute: AttributeListSyntax.Element) -> Bool {
		guard
			case let .attribute(syntax) = initialiserAttribute
		else { return false }

        let attributeName = syntax.attributeName.cast(IdentifierTypeSyntax.self).name.text
		let isComponentMacro = attributeName == Constants.DependencyIgnored

		return isComponentMacro
	}

    private func findInitializers(in dataStructure: DataStructureDeclSyntaxProtocol) -> [InitializerDeclSyntax] {
        let typename = dataStructure.identifier.text
        logger.log("Looking for initializers in \(typename)...", kind: .debug)

        let initializers: [InitializerDeclSyntax] = dataStructure.memberBlock.members.compactMap { child in
            guard let initialiser = child.decl.as(InitializerDeclSyntax.self) else { return nil }

			let isInjectable = initialiser.attributes.contains { attribute in
				guard case let .attribute(attributes) = attribute else { return false }
				return attributes.attributeName.description == Constants.Inject
			}
            logger.log("Found initializer in \(typename): \(initialiser.description)", kind: .debug)

			if isInjectable {
				logger.log("Initialiser is injectable!", kind: .debug)
				// @mbourke: Detaching will remove any parent nodes to save memory.
				return initialiser.detached
			}

			logger.log("Initialiser not injectable. Ignoring...", kind: .debug)
            return nil
        }

        return initializers
    }

	private func separateParameterList(in initializer: InitializerDeclSyntax) -> [Argument] {
		var arguments: [Argument] = []
        for parameter in initializer.signature.parameterClause.parameters {
			if parameter.attributes.contains(where: isDependencyIgnored(from:)) {
				arguments.append(Argument(declaration: toDeclaration(from: parameter), type: .parameter))
			} else {
				arguments.append(Argument(declaration: toDeclaration(from: parameter), type: .dependency))
			}
		}
		return arguments
	}

	private func toDeclaration(from parameter: FunctionParameterSyntax) -> Declaration {
		Declaration(
			variableName: parameter.firstName.trimmed.text,
			variableType: parameter.type.trimmed,
			value: parameter.defaultValue?.value.trimmedDescription
		)
	}
}
