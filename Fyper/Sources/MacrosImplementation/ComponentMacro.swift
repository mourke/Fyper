//
//  ComponentMacro.swift
//  Fyper
//
//  Created by Mark Bourke on 19/12/2023.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftParser
import SwiftDiagnostics
import SwiftParserDiagnostics
import Foundation
import Shared

public struct ComponentMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let macroName = node.attributeName.cast(IdentifierTypeSyntax.self).name.text

		guard
			declaration.is(ClassDeclSyntax.self) ||
			declaration.is(StructDeclSyntax.self) ||
			declaration.is(ActorDeclSyntax.self)
		else {
			let diagnostic = Diagnostic(
				node: node._syntaxNode,
				message: SyntaxError.onlyDataStructures(macroName: macroName)
			)
			context.diagnose(diagnostic)
			return []
		}

		let dataStructure: DataStructureDeclSyntaxProtocol = (declaration.as(ClassDeclSyntax.self) ?? declaration.as(StructDeclSyntax.self)) ?? declaration.cast(ActorDeclSyntax.self)

		let initialisers: [InitializerDeclSyntax] = dataStructure.memberBlock.members.compactMap {
			$0.decl.as(InitializerDeclSyntax.self)
		}

		let hasNoInjectableInitialisers = initialisers.filter { initialiser in
			let isInjectable = initialiser.attributes.contains { attribute in
				guard case let .attribute(attributes) = attribute else { return false }
				return attributes.attributeName.description == Constants.Inject
			}

			return isInjectable
		}.isEmpty

		if hasNoInjectableInitialisers {
			let fixIts = initialisers.map { initialiser in
				let parameters = initialiser.signature.parameterClause.parameters
					.map({ "\($0.firstName.text):" })
					.joined()
				let newAttributes = AttributeListSyntax {
					AttributeSyntax(attributeName: IdentifierTypeSyntax(name: .identifier(Constants.Inject)))
					for attribute in initialiser.attributes {
						attribute
					}
				}
				return FixIt(
					message: CustomFixItMessage("Mark 'init(\(parameters))' with '@\(Constants.Inject)'"),
					changes: [
						.replace(
							oldNode: initialiser._syntaxNode,
							newNode: initialiser.with(\.attributes, newAttributes)._syntaxNode
						)
					]
				)
			}

			let diagnostic = Diagnostic(
				node: node._syntaxNode,
				message: SyntaxError.mustHaveOneInjectableInit(typeName: dataStructure.identifier.text),
				fixIts: fixIts
			)
			context.diagnose(diagnostic)

			return []
		}

		let macros = declaration.attributes
            .compactMap({ element -> IdentifierTypeSyntax? in
				guard case .attribute(let attribute) = element else { return nil }
                return attribute.attributeName.as(IdentifierTypeSyntax.self)
			})
			.filter({ $0.name.text == Constants.Reusable || $0.name.text == Constants.Singleton })

		if macros.count > 1 {
			let diagnostic = Diagnostic(
				node: node._syntaxNode,
				message: SyntaxError.onlyOneMacro
			)
			context.diagnose(diagnostic)
			return []
		}

		if macroName == Constants.Singleton, let structDecl = declaration.as(StructDeclSyntax.self) {
            let structName = structDecl.name.description
			let becomeClass = FixIt(
				message: CustomFixItMessage("Convert '\(structName)' to a class"),
				changes: [
					.replace(
                        oldNode: structDecl.structKeyword._syntaxNode,
                        newNode: structDecl.structKeyword.with(\.tokenKind, .keyword(.class))._syntaxNode
					)
				]
			)
			let diagnostic = Diagnostic(
				node: node._syntaxNode,
				message: SyntaxError.valueTypeSingleton,
				fixIt: becomeClass
			)
			context.diagnose(diagnostic)

			return []
		}

		return []
    }
    
    private static func replacingInheritanceClause(
        of declaration: DataStructureDeclSyntaxProtocol,
        newClause newInheritanceClause: InheritanceClauseSyntax
    ) -> Syntax {
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            return structDecl.with(\.inheritanceClause, newInheritanceClause).formatted()._syntaxNode
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            return classDecl.with(\.inheritanceClause, newInheritanceClause).formatted()._syntaxNode
        } else {
            return declaration.cast(ActorDeclSyntax.self).with(\.inheritanceClause, newInheritanceClause).formatted()._syntaxNode
        }
    }
}
