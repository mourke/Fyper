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

	/// The name of the Xcode target whose Container is currently being generated. This is used to generate the name of the Container class.
	let targetName: String

    /// The analysis of the target source files.
	let analysis: Analysis

    ///
    /// Generates a file of the form 'TargetName+Container.swift' that contains all the injectable components.
	///
	/// - Throws:   Exception if the file being generated contains malformed swift.
    ///
    func generate() throws -> String {
		let components = analysis.components

		let containerTypename = "\(targetName)Container"
		logger.log("Generating \(containerTypename)...", kind: .debug)

		let internallyProvidedTypenames = components.map(\.exposedAs)

		var allDependencies: [Declaration] = []
		components.flatMap(\.dependencies).forEach { dependency in
			guard !allDependencies.contains(dependency) else { return }
			allDependencies.append(dependency)
		}

		logger.log("\(allDependencies.count) unique dependencies found.", kind: .debug)

		var externalDependencies: [Declaration] = []
		for dependency in allDependencies {
			guard !internallyProvidedTypenames.contains(dependency.variableType) &&
					containerTypename != dependency.variableType
			else { continue }
			externalDependencies.append(dependency)
		}

		logger.log("\(externalDependencies.count) external dependencies found.", kind: .debug)

		externalDependencies.sort { $0.variableName.lowercased() < $1.variableName.lowercased() }

		let singletons = components.filter(\.isSingleton)

		logger.log("\(singletons.count) singletons found.", kind: .debug)

		let generatedFileSyntax = try SourceFileSyntax {
			for importStatement in analysis.imports {
				ImportDeclSyntax(path: .init(itemsBuilder: {
					importStatement
				}))
			}

			try ClassDeclSyntax("public final class \(raw: containerTypename)") {

				buildMembers(dependencies: externalDependencies)

				buildSingletons(singletons)

				buildInitializer(dependencies: externalDependencies)

				let builders = buildComponentBuilders(
					singletonVariableNames: singletons.map(\.typename).map(\.lowercasingFirst),
					externalDependencyVariableNames: externalDependencies.map(\.variableName),
					containerTypename: containerTypename
				)

				for function in builders {
					function
				}
			}
		}

		var containerFile = ""
		generatedFileSyntax.formatted().write(to: &containerFile)
		logger.log("Successfully generated! \n \(containerFile)", kind: .debug)

		return containerFile
    }

    private func buildMembers(dependencies: [Declaration]) -> MemberBlockItemListSyntax {
		logger.log("Building \(dependencies.count) members...", kind: .debug)

        return MemberBlockItemListSyntax {
			for dependency in dependencies {
				VariableDeclSyntax(
                    modifiers: DeclModifierListSyntax(arrayLiteral: DeclModifierSyntax(name: .keyword(.private))),
					.let,
					name: IdentifierPatternSyntax(identifier: .identifier(dependency.variableName)).cast(PatternSyntax.self),
                    type: .init(type: IdentifierTypeSyntax(name: .identifier(dependency.variableType)))
				)
			}
		}
	}

    private func buildSingletons(_ singletons: [Component]) -> MemberBlockItemListSyntax {
		logger.log("Building \(singletons.count) singletons...", kind: .debug)

        return MemberBlockItemListSyntax {
			for singleton in singletons {
				VariableDeclSyntax(
					modifiers: .init(arrayLiteral: .init(name: .keyword(.private)), .init(name: .keyword(.lazy))),
					.var,
					name: .init(IdentifierPatternSyntax(identifier: .identifier(singleton.typename.lowercasingFirst))),
                    type: TypeAnnotationSyntax(type: IdentifierTypeSyntax(name: .identifier( singleton.exposedAs))),
					initializer: .init(value: FunctionCallExprSyntax(
                        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("build\(singleton.typename)")),
						leftParen: .leftParenToken(),
						arguments: [],
						rightParen: .rightParenToken()
					))
				)
			}
		}
	}

	private func buildInitializer(dependencies: [Declaration]) -> InitializerDeclSyntax {
		logger.log("Building initializer...", kind: .debug)
		let parameterList = FunctionParameterListBuilder.FinalResult {
			for dependency in dependencies {
				FunctionParameterSyntax(
					firstName: .identifier(dependency.variableName),
                    type: IdentifierTypeSyntax(name: .identifier(dependency.variableType))
				)
			}
		}
		return InitializerDeclSyntax(
            modifiers: DeclModifierListSyntax(arrayLiteral: DeclModifierSyntax(name: .keyword(.public))),
            signature: .init(parameterClause: .init(parameters: parameterList))
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
	) -> [FunctionDeclSyntax] {
		logger.log("Building \(analysis.components.count) builders...", kind: .debug)

		return analysis.components.map { component in
			FunctionDeclSyntax(
				name: .identifier("build\(component.typename)"),
				signature: .init(parameterClause: .init(parametersBuilder: {
					for parameter in component.parameters {
						FunctionParameterSyntax(
							firstName: .identifier(parameter.variableName),
                            type: IdentifierTypeSyntax(name: .identifier(parameter.variableType))
						)
					}
				}), returnClause: .init(type: builderReturnType(for: component))),
				bodyBuilder: {
					FunctionCallExprSyntax(
                        calledExpression: DeclReferenceExprSyntax(baseName: .identifier(component.typename)),
						leftParen: .leftParenToken(),
						rightParen: .rightParenToken()
					) {
						for argument in component.arguments {
							if argument.declaration.variableType == containerTypename {
                                LabeledExprSyntax(
									label: argument.declaration.variableName,
                                    expression: DeclReferenceExprSyntax(baseName: .keyword(.self))
								)
							} else if argument.type != .parameter && !singletonVariableNames.contains(argument.declaration.variableName) && !externalDependencyVariableNames.contains(argument.declaration.variableName) 
							{
								// @mbourke: If it's not a param, singleton or external dependency, call
								// the build function directly
                                LabeledExprSyntax(
									label: argument.declaration.variableName,
									expression: FunctionCallExprSyntax(
                                        calledExpression: DeclReferenceExprSyntax(baseName: .identifier("build\(argument.declaration.variableType)")),
										leftParen: .leftParenToken(),
										arguments: [],
										rightParen: .rightParenToken()
									)
								)
							} else {
                                LabeledExprSyntax(
									label: argument.declaration.variableName,
                                    expression: DeclReferenceExprSyntax(baseName: .identifier(argument.declaration.variableName))
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
            return SomeOrAnyTypeSyntax(someOrAnySpecifier: .keyword(.some), constraint: IdentifierTypeSyntax(name: .identifier(component.exposedAs)))
		} else {
            return IdentifierTypeSyntax(name: .identifier(component.exposedAs))
		}
	}
}
