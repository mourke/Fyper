//
//  Analyser.swift
//  Fyper
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

enum AnalyserError: Error {
    case unsupportedInitializer(_ syntax: FunctionCallExprSyntax)
}

/// Analyses the code and returns a calling graph of all classes that need to be injected.
struct Analyser {

	let logger: Logger

	/// Parsed file structures obtained from the *Parser* stage.
	let fileStructures: [FileStructure]

	func analyse() throws -> Set<Component> {
		return try findComponents()
	}

	// MARK: - Searching for Components

	private func findComponents() throws -> Set<Component> {
		var components: Set<Component> = []

		for (filePath, syntaxStructure) in fileStructures {
			logger.log("Looking for Components in \(filePath)...", kind: .debug)
			let componentDeclarations = findComponentDeclarations(syntax: syntaxStructure)
			logger.log("Found \(componentDeclarations.count) Component(s).", kind: .debug)

			for (macro, dataStructure) in componentDeclarations {
				let typename = dataStructure.identifier.text
				let (exposedAs, isPublic, isSingleton) = extractMetadata(from: macro)

				for initializer in findInitializers(in: dataStructure) {

					let (dependencies, parameters) = separateParameterList(in: initializer)

					let component = Component(
						typename: typename,
						exposedAs: exposedAs ?? typename,
						parameters: parameters,
						dependencies: dependencies,
						isPublic: isPublic,
						isSingleton: isSingleton
					)

					components.insert(component)
				}
			}
		}

		return components
	}

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

	private func separateParameterList(in initializer: InitializerDeclSyntax) -> (dependencies: FunctionParameterListSyntax, parameters: FunctionParameterListSyntax) {
		var parameters: [FunctionParameterSyntax] = []
		var dependencies: [FunctionParameterSyntax] = []
		for parameter in initializer.signature.input.parameterList {
			if let attributes = parameter.attributes, 
				attributes.contains(where: isDependencyIgnored(from:)) {
				parameters.append(cleanParameter(parameter))
			} else {
				dependencies.append(cleanParameter(parameter))
			}
		}
		return (FunctionParameterListBuilder.buildFinalResult(dependencies), FunctionParameterListBuilder.buildFinalResult(parameters))
	}

	private func cleanParameter(_ parameter: FunctionParameterSyntax) -> FunctionParameterSyntax {
		FunctionParameterSyntax(
			firstName: parameter.firstName.trimmed,
			secondName: parameter.secondName?.trimmed,
			type: parameter.type.trimmed
		)
	}
}
