//
//  Argument.swift
//  Fyper
//
//  Created by Mark Bourke on 13/12/2023.
//

import Foundation

enum ArgumentType {
	case parameter, dependency
}

/// An argument is a variable that is passed to a function
struct Argument {

	/// The declaration (name and type) of the argument
	let declaration: Declaration

	/// The type of the argument (whether it is a parameter or a dependency).
	let type: ArgumentType
}
