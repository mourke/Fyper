//
//  Generator.swift
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

		let containerType = IdentifierTypeSyntax(name: .identifier("\(targetName)Container"))
		logger.log("Generating \(containerType.name.text)...", kind: .debug)

		let internallyProvidedTypes = components.map(\.exposedAs)

		var allDependencies: [Declaration] = []
		components.flatMap(\.dependencies).forEach { dependency in
			guard !allDependencies.contains(dependency) else { return }
			allDependencies.append(dependency)
		}

		logger.log("\(allDependencies.count) unique dependencies found.", kind: .debug)

		var externalDependencies: [Declaration] = []
		for dependency in allDependencies {
			guard !internallyProvidedTypes.contains(where: { $0.isEqual(to: dependency.variableType) }) &&
					!dependency.variableType.isEqual(to: containerType)
			else { continue }

			// @mbourke: Don't directly use `variableName` that user entered as there could be
			// collisions if two variables have the same name but different types.
			let cleanedDeclaration = Declaration(
				variableName: getUnderlyingSimpleType(from: dependency.variableType).name.text.lowercasingFirst,
				variableType: dependency.variableType
			)
			externalDependencies.append(cleanedDeclaration)
		}

		logger.log("\(externalDependencies.count) external dependencies found.", kind: .debug)

		externalDependencies.sort { $0.variableName.lowercased() < $1.variableName.lowercased() }

		let singletons = components.filter(\.isSingleton).map {
			let simpleTypeName = getUnderlyingSimpleType(from: $0.type).name.text
			return Declaration(
				variableName: simpleTypeName.lowercasingFirst,
				variableType: $0.exposedAs,
				value: "build\(simpleTypeName)"
			)
		}

		logger.log("\(singletons.count) singletons found.", kind: .debug)

		let generatedFileSyntax = try SourceFileSyntax {
			for importStatement in analysis.imports {
				ImportDeclSyntax(path: .init(itemsBuilder: {
					importStatement
				}))
			}

			try ClassDeclSyntax("public final class \(raw: containerType.name.text)") {

				buildMembers(dependencies: externalDependencies)

				buildSingletons(singletons)

				buildInitializer(dependencies: externalDependencies)

				let builders = buildComponentBuilders(
					availableTypes: externalDependencies + singletons,
					containerType: containerType
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
                    type: .init(type: dependency.variableType)
				)
			}
		}
	}

    private func buildSingletons(_ singletons: [Declaration]) -> MemberBlockItemListSyntax {
		logger.log("Building \(singletons.count) singletons...", kind: .debug)

        return MemberBlockItemListSyntax {
			for singleton in singletons {
				VariableDeclSyntax(
					modifiers: .init(arrayLiteral: .init(name: .keyword(.private)), .init(name: .keyword(.lazy))),
					.var,
					name: .init(IdentifierPatternSyntax(identifier: .identifier(singleton.variableName))),
					type: TypeAnnotationSyntax(type: singleton.variableType),
					initializer: .init(value: FunctionCallExprSyntax(
						calledExpression: DeclReferenceExprSyntax(baseName: .identifier(singleton.value.unsafelyUnwrapped)),
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
                    type: dependency.variableType
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
		availableTypes: [Declaration],
		containerType: IdentifierTypeSyntax
	) -> [FunctionDeclSyntax] {
		logger.log("Building \(analysis.components.count) builders...", kind: .debug)

		// TODO: Add support for throwing and async initialisers.

		return analysis.components.map { component in
			let componentSimpleType = getUnderlyingSimpleType(from: component.type)
			return FunctionDeclSyntax(
				name: .identifier("build\(componentSimpleType.name.text)"),
				signature: .init(parameterClause: .init(parametersBuilder: {
					for parameter in component.parameters {
						FunctionParameterSyntax(
							firstName: .identifier(parameter.variableName),
                            type: parameter.variableType,
							defaultValue: parameter.value.map({InitializerClauseSyntax(value: ExprSyntax(stringLiteral: $0))})
						)
					}
				}), returnClause: .init(type: builderReturnType(for: component))),
				bodyBuilder: {
					FunctionCallExprSyntax(
						calledExpression: DeclReferenceExprSyntax(baseName: componentSimpleType.name),
						leftParen: .leftParenToken(),
						rightParen: .rightParenToken()
					) {
						for argument in component.arguments {
							if argument.type == .parameter {
								LabeledExprSyntax(
									label: argument.declaration.variableName,
									expression: DeclReferenceExprSyntax(baseName: .identifier(argument.declaration.variableName))
								)
							} else if getUnderlyingSimpleType(from: argument.declaration.variableType).name.text == containerType.name.text {
                                LabeledExprSyntax(
									label: argument.declaration.variableName,
                                    expression: DeclReferenceExprSyntax(baseName: .keyword(.self))
								)
							} else if let internalType = availableTypes.first(where: {
								$0.variableType.isEqual(to: argument.declaration.variableType)
							}) {
								// @mbourke: Note: The variable name that the initialiser has
								// could be different to what is inside the generated container.
								LabeledExprSyntax(
									label: argument.declaration.variableName,
									expression: DeclReferenceExprSyntax(baseName: .identifier(internalType.variableName))
								)
							} else {
								// @mbourke: If it's not a singleton or external dependency, call
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
							}
						}
					}
				}
			)
		}
	}

	private func getUnderlyingSimpleType(from type: TypeSyntaxProtocol) -> IdentifierTypeSyntax {
		func _getUnderlyingType(from type: SyntaxProtocol) -> IdentifierTypeSyntax? {
			let children = type.children(viewMode: .fixedUp)

			guard let simpleType = type.as(IdentifierTypeSyntax.self) else {
				return children.compactMap(_getUnderlyingType(from:)).first
			}

			return simpleType
		}
		// @mbourke: We know that all types are backed by simple types so we can force unwrap
		return _getUnderlyingType(from: type)!
	}

	private func builderReturnType(for component: Component) -> TypeSyntaxProtocol {
		if component.isExposedAsProtocol {
			if let optionalExposed = component.exposedAs.as(OptionalTypeSyntax.self) {
				let wrappedType = SomeOrAnyTypeSyntax(someOrAnySpecifier: .keyword(.some), constraint: optionalExposed.wrappedType)
				return OptionalTypeSyntax(wrappedType: TupleTypeSyntax(elements: .init(arrayLiteral: .init(type: wrappedType))))
			} else {
				return SomeOrAnyTypeSyntax(someOrAnySpecifier: .keyword(.some), constraint: component.exposedAs)
			}
		} else {
			return component.exposedAs
		}
	}
}
