//
//  Analyser.swift
//  Fyper
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

/// Analyses the code and returns a calling graph of all classes that need to be injected.
struct Analyser {

	let logger: Logger

	/// Parsed file structures obtained from the *Parser* stage.
	let fileStructures: [FileStructure]

	func analyse() -> [Component] {
		var components: [Component] = []

		for (filePath, syntaxStructure) in fileStructures {
			logger.log("Looking for Components in \(filePath)...", kind: .debug)
			let componentDeclarations = findComponentDeclarations(syntax: syntaxStructure)
			logger.log("Found \(componentDeclarations.count) Component(s).", kind: .debug)

			for (macro, dataStructure) in componentDeclarations {
				logger.log("Extracting metadata from \(dataStructure.identifier.text)...", kind: .debug)
				let typename = dataStructure.identifier.text
				let (exposedAs, isPublic, isSingleton) = extractMetadata(from: macro)

				for initializer in findInitializers(in: dataStructure) {
					let component = Component(
						typename: typename,
						exposedAs: exposedAs ?? typename,
						arguments: separateParameterList(in: initializer),
						isPublic: isPublic,
						isSingleton: isSingleton
					)

					components.append(component)
				}
			}
		}

		return components
	}

	// MARK: - Searching for Components

	private func findComponentDeclarations(syntax: SyntaxProtocol) -> [(AttributeSyntax, DataStructureDeclSyntaxProtocol)] {
		let children = syntax.children(viewMode: .fixedUp)

		guard syntax.kind == .classDecl ||
				syntax.kind == .structDecl ||
				syntax.kind == .actorDecl
		else {
			return children.flatMap { findComponentDeclarations(syntax: $0) }
		}

		let dataStructure: DataStructureDeclSyntaxProtocol = (syntax.as(ClassDeclSyntax.self) ?? syntax.as(StructDeclSyntax.self)) ?? syntax.cast(ActorDeclSyntax.self)
		
		guard let attributes = dataStructure.attributes,
			  let macro = attributes.compactMap(componentMacro(from:)).first else {
			return []
		}

		return [(macro, dataStructure)]
	}

    private func componentMacro(from initialiserAttribute: AttributeListSyntax.Element) -> AttributeSyntax? {
        guard
            case let .attribute(syntax) = initialiserAttribute
        else { return nil }

        let attributeName = syntax.attributeName.cast(SimpleTypeIdentifierSyntax.self).name.text
		let isComponentMacro = attributeName == Constants.Reusable || attributeName == Constants.Singleton

		return isComponentMacro ? syntax : nil
    }

	private func extractMetadata(from syntax: AttributeSyntax) -> (exposedAs: String?, isPublic: Bool, isSingleton: Bool) {
		let attributeName = syntax.attributeName.cast(SimpleTypeIdentifierSyntax.self).name.text
		let isSingleton = attributeName == Constants.Singleton
		var exposedAs: String?
		var isPublic = false

		if case let .argumentList(arguments) = syntax.argument {
			for argument in arguments {
				switch argument.label?.text {
				case Constants.ExposeAs:
					let identifier = argument.expression.cast(IdentifierExprSyntax.self).identifier
					exposedAs = identifier.text
				case Constants.Scope:
					let identifier = argument.expression.cast(MemberAccessExprSyntax.self).name
					isPublic = identifier.text == Constants.Public
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

		let attributeName = syntax.attributeName.cast(SimpleTypeIdentifierSyntax.self).name.text
		let isComponentMacro = attributeName == Constants.DependencyIgnored

		return isComponentMacro
	}

    private func findInitializers(in dataStructure: DataStructureDeclSyntaxProtocol) -> [InitializerDeclSyntax] {
        let typename = dataStructure.identifier.text
        logger.log("Looking for initializers in \(typename)...", kind: .debug)

        let initializers: [InitializerDeclSyntax] = dataStructure.memberBlock.members.compactMap { child in
            let declaration = child.decl
            guard declaration.kind == .initializerDecl else {
                return nil
            }

            let initialiser = declaration.cast(InitializerDeclSyntax.self)
            logger.log("Found initializer in \(typename): \(initialiser.description)", kind: .debug)

            return initialiser.detach() // save memory by detaching
        }

        return initializers
    }

	private func separateParameterList(in initializer: InitializerDeclSyntax) -> [Argument] {
		var arguments: [Argument] = []
		for parameter in initializer.signature.input.parameterList {
			if let attributes = parameter.attributes, 
				attributes.contains(where: isDependencyIgnored(from:)) {
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
			variableType: parameter.type.cast(SimpleTypeIdentifierSyntax.self).name.text
		)
	}
}
