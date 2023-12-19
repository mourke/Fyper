//
//  InjectMacro.swift
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

public struct InjectMacro: PeerMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		// TODO: Raise error if applied to anything but initialiser decl
		// TODO: Raise error if initialiser is async or throwing. we don't support that yet
		return []
	}
}
