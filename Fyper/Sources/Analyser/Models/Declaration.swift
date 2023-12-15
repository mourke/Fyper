//
//  Declaration.swift
//	Fyper
//
//  Created by Mark Bourke on 12/12/2023.
//

import Foundation

/// A declaration is any `let`, `var` or function argument that specifies a variable name and its corresponding type
struct Declaration: Equatable {

	/// The name of the variable
	let variableName: String

	/// The simple type of the variable as a string. This does not correctly encode generic types.
	let variableType: String
}
