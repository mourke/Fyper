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
		let macroName = node.attributeName.cast(SimpleTypeIdentifierSyntax.self).name.text

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

		let macros = declaration.attributes?
			.compactMap({ element -> SimpleTypeIdentifierSyntax? in
				guard case .attribute(let attribute) = element else { return nil }
				return attribute.attributeName.as(SimpleTypeIdentifierSyntax.self)
			})
			.filter({ $0.name.text == Constants.Reusable || $0.name.text == Constants.Singleton })

		if let macros, macros.count > 1 {
			let diagnostic = Diagnostic(
				node: node._syntaxNode,
				message: SyntaxError.onlyOneMacro
			)
			context.diagnose(diagnostic)
			return []
		}

		if let argument = node.argument,
		   case .argumentList(let argList) = argument,
		   let exposedAs = argList.first(where: { $0.label?.text == Constants.ExposeAs }),
		   let protocolName = exposedAs.expression.as(IdentifierExprSyntax.self)?.identifier.text,
		   let inheritanceClause = dataStructure.inheritanceClause
		{
			let conformsToExposedAs = inheritanceClause.inheritedTypeCollection
				.compactMap({ $0.typeName.cast(SimpleTypeIdentifierSyntax.self) })
				.contains(where: { $0.name.text == protocolName })

			if !conformsToExposedAs {
				let newInheritanceClause = TypeInheritanceClauseSyntax {
					let protocolType = SimpleTypeIdentifierSyntax(name: .identifier(protocolName))
					for inheritance in inheritanceClause.inheritedTypeCollection {
						inheritance
					}
					InheritedTypeSyntax(typeName: protocolType)
				}

				let addProtocolConformance = FixIt(
					message: CustomFixItMessage("Add conformance to '\(protocolName)'"),
					changes: [
						.replace(
							oldNode: inheritanceClause._syntaxNode,
							newNode: newInheritanceClause._syntaxNode
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

		if macroName == Constants.Singleton,
		   let structDecl = declaration.as(StructDeclSyntax.self),
		   !isNonCopyableStruct(structDecl)
		{
			let structName = structDecl.identifier.description
			let becomeClass = FixIt(
				message: CustomFixItMessage("Convert '\(structName)' to a class"),
				changes: [
					.replace(
						oldNode: structDecl._syntaxNode,
						newNode: structDecl.with(\.structKeyword, .keyword(.class))._syntaxNode
					)
				]
			)
			let inheritanceClause = TypeInheritanceClauseSyntax {
				let nonCopyable = SuppressedTypeSyntax(
					withoutTilde: .prefixOperator("~"),
					patternType: SimpleTypeIdentifierSyntax(name: .identifier(Constants.Copyable))
				)
				InheritedTypeSyntax(typeName: nonCopyable)
				if let inheritanceClause = structDecl.inheritanceClause {
					for inheritance in inheritanceClause.inheritedTypeCollection {
						inheritance
					}
				}
			}
			let addNonCopyable = FixIt(
				message: CustomFixItMessage("Mark '\(structName)' as non-copyable"),
				changes: [
					.replace(
						oldNode: structDecl._syntaxNode,
						newNode: structDecl.with(\.inheritanceClause, inheritanceClause)._syntaxNode
					)
				]
			)
			let diagnostic = Diagnostic(
				node: node._syntaxNode,
				message: SyntaxError.valueTypeSingleton,
				fixIts: [becomeClass, addNonCopyable]
			)
			context.diagnose(diagnostic)

			return []
		}

		return []
    }

	private static func isNonCopyableStruct(_ structDecl: StructDeclSyntax) -> Bool {
		guard let inheritanceClause = structDecl.inheritanceClause else {
			return false
		}
		return inheritanceClause.inheritedTypeCollection
			.compactMap({ $0.typeName.as(SuppressedTypeSyntax.self) })
			.contains(where: {
				guard let type = $0.patternType.as(SimpleTypeIdentifierSyntax.self) else {
					return false
				}
				return type.name.text == Constants.Copyable && $0.withoutTilde == .prefixOperator("~")
			})
	}
}

@main
struct FyperMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ComponentMacro.self,
    ]
}
