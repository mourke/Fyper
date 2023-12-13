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

struct Argument: Equatable {
	let declaration: Declaration
	let type: ArgumentType
}
