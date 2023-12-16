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

        if let arguments = node.arguments?.cast(LabeledExprListSyntax.self),
		   let exposedAs = arguments.first(where: { $0.label?.text == Constants.ExposeAs }),
           let protocolName = exposedAs.expression.as(DeclReferenceExprSyntax.self)?.baseName.text
		{
            let conformsToExposedAs = dataStructure.inheritanceClause?.inheritedTypes
                .compactMap({ $0.type.as(IdentifierTypeSyntax.self) })
				.contains(where: { $0.name.text == protocolName }) ?? false

			if !conformsToExposedAs {
                let newInheritanceClause = InheritanceClauseSyntax {
                    let protocolType = IdentifierTypeSyntax(name: .identifier(protocolName))
                    if let inheritedTypes = dataStructure.inheritanceClause?.inheritedTypes {
                        for inheritance in inheritedTypes {
                            inheritance
                        }
                    }
                    InheritedTypeSyntax(type: protocolType)
				}

				let addProtocolConformance = FixIt(
					message: CustomFixItMessage("Add conformance to '\(protocolName)'"),
					changes: [
						.replace(
							oldNode: dataStructure._syntaxNode,
                            newNode: replacingInheritanceClause(
                                of: dataStructure,
                                newClause: newInheritanceClause
                            )
						)
					]
				)

				let diagnostic = Diagnostic(
					node: declaration._syntaxNode,
					message: SyntaxError.mustConformToExposedAs(
						typeName: dataStructure.identifier.text,
						protocolName: protocolName
					),
					fixIts: [addProtocolConformance]
				)
				context.diagnose(diagnostic)

				return []
			}
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
				fixIts: [becomeClass]
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

@main
struct FyperMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ComponentMacro.self,
    ]
}
