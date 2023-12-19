//
//  FyperMacrosPlugin.swift
//  Fyper
//
//  Created by Mark Bourke on 19/12/2023.
//

import Foundation
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FyperMacrosPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		ComponentMacro.self,
		InjectMacro.self
	]
}
