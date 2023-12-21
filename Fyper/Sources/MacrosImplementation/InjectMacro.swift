//
//  InjectMacro.swift
//  Fyper
//
//  Created by Mark Bourke on 19/12/2023.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParserDiagnostics
import Foundation
import Shared

public struct InjectMacro: PeerMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard let initialiser = declaration.as(InitializerDeclSyntax.self) else {
			let diagnostic = Diagnostic(
				node: node._syntaxNode,
				message: SyntaxError.onlyInitialisers
			)
			context.diagnose(diagnostic)
			return []
		}

		if initialiser.signature.effectSpecifiers?.asyncSpecifier != nil {
			let diagnostic = Diagnostic(
				node: initialiser._syntaxNode,
				message: SyntaxError.noAsync
			)
			context.diagnose(diagnostic)
			return []
		}

		if initialiser.signature.effectSpecifiers?.throwsSpecifier != nil {
			let diagnostic = Diagnostic(
				node: initialiser._syntaxNode,
				message: SyntaxError.noThrowing
			)
			context.diagnose(diagnostic)
			return []
		}

		return []
	}
}
