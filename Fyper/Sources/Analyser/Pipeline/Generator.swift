//
//  Validator.swift
//  Fyper
//
//  Created by Mark Bourke on 02/03/2022.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

/// Generates Container swift file. This should be called after Analyser.
struct Generator {

    let logger: Logger

	let targetName: String

    /// The Components that should generated inside the Container, obtained from the *Analyser* stage.
    let components: [Component]

    ///
    /// Generates a file of the form 'TargetName+Container.swift' that contains all the injectable components.
	///
	/// - Throws:   Exception if the file being generated contains malformed swift.
    ///
    func generate() throws -> String {
		let containerTypename = "\(targetName)Container"
		let internallyProvidedTypenames = components.map(\.exposedAs)
		var allDependencies: [Declaration] = []

		components.flatMap(\.dependencies).forEach { dependency in
			guard !allDependencies.contains(dependency) else { return }
			allDependencies.append(dependency)
		}
		var externalDependencies: [Declaration] = []

		for dependency in allDependencies {
			guard !internallyProvidedTypenames.contains(dependency.variableType) &&
					containerTypename != dependency.variableType
			else { continue }
			externalDependencies.append(dependency)
		}

		externalDependencies.sort { $0.variableName.lowercased() < $1.variableName.lowercased() }

		let singletons = components.filter(\.isSingleton)
		let classDecl = try ClassDeclSyntax("public final class \(raw: containerTypename)") {

			buildMembers(dependencies: externalDependencies)

			buildSingletons(singletons)

			buildInitializer(dependencies: externalDependencies)

			let builders = try buildComponentBuilders(
				singletonVariableNames: singletons.map(\.typename).map(\.lowercasingFirst),
				externalDependencyVariableNames: externalDependencies.map(\.variableName),
				containerTypename: containerTypename
			)

			for function in builders {
				function
			}
		}

		var containerFile = ""
		classDecl.formatted().write(to: &containerFile)
		return containerFile
    }

	private func buildMembers(dependencies: [Declaration]) -> MemberDeclListSyntax {
		MemberDeclListSyntax {
			for dependency in dependencies {
				VariableDeclSyntax(
					modifiers: ModifierListSyntax(arrayLiteral: DeclModifierSyntax(name: .keyword(.private))),
					.let,
					name: IdentifierPatternSyntax(identifier: .identifier(dependency.variableName)).cast(PatternSyntax.self),
					type: .init(type: SimpleTypeIdentifierSyntax(name: .identifier(dependency.variableType)))
				)
			}
		}
	}

	private func buildSingletons(_ singletons: [Component]) -> MemberDeclListSyntax {
		MemberDeclListSyntax {
			for singleton in singletons {
				DeclSyntax("private lazy var \(raw: singleton.typename.lowercasingFirst): \(raw: singleton.exposedAs) = build\(raw: singleton.typename)()").cast(VariableDeclSyntax.self)
			}
		}
	}

	private func buildInitializer(dependencies: [Declaration]) -> InitializerDeclSyntax {
		let parameterList = FunctionParameterListBuilder.FinalResult {
			for dependency in dependencies {
				FunctionParameterSyntax(
					firstName: .identifier(dependency.variableName),
					type: SimpleTypeIdentifierSyntax(name: .identifier(dependency.variableType))
				)
			}
		}
		return InitializerDeclSyntax(
			modifiers: ModifierListSyntax(arrayLiteral: DeclModifierSyntax(name: .keyword(.public))),
			signature: .init(input: .init(parameterList: parameterList))
		) {
			for dependency in dependencies {
				let name = dependency.variableName
				"self.\(raw: name) = \(raw: name)"
			}
		}
	}

	private func buildComponentBuilders(
		singletonVariableNames: [String],
		externalDependencyVariableNames: [String],
		containerTypename: String
	) throws -> [FunctionDeclSyntax] {
		components.map { component in
			FunctionDeclSyntax(
				identifier: .identifier("build\(component.typename)"),
				signature: .init(input: .init(parameterListBuilder: {
					for parameter in component.parameters {
						FunctionParameterSyntax(
							firstName: .identifier(parameter.variableName),
							type: SimpleTypeIdentifierSyntax(name: .identifier(parameter.variableType))
						)
					}
				}), output: .init(returnType: builderReturnType(for: component))),
				bodyBuilder: {
					FunctionCallExprSyntax(
						calledExpression: IdentifierExprSyntax(identifier: .identifier(component.typename)),
						leftParen: .leftParenToken(),
						rightParen: .rightParenToken()
					) {
						for argument in component.arguments {
							if argument.declaration.variableType == containerTypename {
								TupleExprElementSyntax(
									label: argument.declaration.variableName,
									expression: IdentifierExprSyntax(identifier: .keyword(.self))
								)
							} else if argument.type != .parameter && !singletonVariableNames.contains(argument.declaration.variableName) && !externalDependencyVariableNames.contains(argument.declaration.variableName) {
								TupleExprElementSyntax(
									label: argument.declaration.variableName,
									expression: FunctionCallExprSyntax(
										calledExpression: IdentifierExprSyntax(identifier: .identifier("build\(argument.declaration.variableType)")),
										leftParen: .leftParenToken(),
										argumentList: [], 
										rightParen: .rightParenToken()
									)
								)
							} else {
								TupleExprElementSyntax(
									label: argument.declaration.variableName,
									expression: IdentifierExprSyntax(identifier: .identifier(argument.declaration.variableName))
								)
							}
						}
					}
				}
			)
		}
	}

	private func builderReturnType(for component: Component) -> TypeSyntaxProtocol {
		if component.isExposedAsProtocol {
			return ConstrainedSugarTypeSyntax(someOrAnySpecifier: .keyword(.some), baseType: SimpleTypeIdentifierSyntax(name: .identifier(component.exposedAs)))
		} else {
			return SimpleTypeIdentifierSyntax(name: .identifier(component.exposedAs))
		}
	}
}
