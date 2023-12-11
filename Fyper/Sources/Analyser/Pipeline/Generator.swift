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
    let components: Set<Component>

    ///
    /// Generates a file of the form 'TargetName+Container.swift' that contains all the injectable components.
	///
	/// - Throws:   Exception if the file being generated contains malformed swift.
    ///
    func generate() throws -> String {
		let internallyProvidedTypenames = components.map(\.exposedAs)
		let allDependencies = components.flatMap(\.dependencies)
		var internalDependencies: [FunctionParameterSyntax] = []
		var externalDependencies: [FunctionParameterSyntax] = []

		for dependency in allDependencies {
			if let typename = dependency.type.as(SimpleTypeIdentifierSyntax.self)?.name.text,
			   internallyProvidedTypenames.contains(typename) {
				internalDependencies.append(dependency)
			} else {
				externalDependencies.append(dependency)
			}
		}

		let singletonTypes = components.filter(\.isSingleton).map(\.typename)
		let classDecl = try ClassDeclSyntax("public final class \(raw: targetName)Container") {

			buildMembers(dependencies: externalDependencies)

			buildSingletons(of: singletonTypes)

			buildInitializer(dependencies: externalDependencies)

			for function in try buildComponentBuilders(singletons: singletonTypes) {
				function
			}
		}

		var containerFile = ""
		classDecl.formatted().write(to: &containerFile)
		return containerFile
    }

	private func buildMembers(dependencies: [FunctionParameterSyntax]) -> MemberDeclListSyntax {
		MemberDeclListSyntax {
			for dependency in dependencies {
				VariableDeclSyntax(
					.let,
					name: IdentifierPatternSyntax(identifier: dependency.firstName).cast(PatternSyntax.self),
					type: .init(type: dependency.type)
				)
			}
		}
	}

	private func buildSingletons(of types: [String]) -> MemberDeclListSyntax {
		MemberDeclListSyntax {
			for type in types {
				DeclSyntax("lazy var \(raw: type.lowercasingFirst) = build\(raw: type)()").cast(VariableDeclSyntax.self)
			}
		}
	}

	private func buildInitializer(dependencies: [FunctionParameterSyntax]) -> InitializerDeclSyntax {
		let parameterList = FunctionParameterListBuilder.buildFinalResult(dependencies)
		return InitializerDeclSyntax(signature: .init(input: .init(parameterList: parameterList))) {
			for dependency in dependencies {
				let name = dependency.firstName.text
				"self.\(raw: name) = \(raw: name)"
			}
		}
	}

	private func buildComponentBuilders(singletons: [String]) throws -> [FunctionDeclSyntax] {
		try components.map { component in
			try FunctionDeclSyntax("func build\(raw: component.typename)() -> \(raw: component.exposedAs)") {
				"fatalError()"
			}
		}
	}
}
