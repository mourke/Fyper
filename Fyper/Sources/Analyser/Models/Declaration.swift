//
//  Declaration.swift
//	Fyper
//
//  Created by Mark Bourke on 12/12/2023.
//

import Foundation
import SwiftSyntax

/// A declaration is any `let`, `var` or function argument that specifies a variable name and its corresponding type
struct Declaration: Equatable {
	/// The name of the variable
	let variableName: String

	/// The type of the variable.
	let variableType: TypeSyntaxProtocol

	/// The value of the declaration (if any).
	let value: String?

	static func == (lhs: Declaration, rhs: Declaration) -> Bool {
		lhs.variableName == rhs.variableName &&
		lhs.variableType.isEqual(to: rhs.variableType) &&
		lhs.value == rhs.value
	}

	init(variableName: String, variableType: TypeSyntaxProtocol, value: String? = nil) {
		self.variableName = variableName
		self.variableType = variableType
		self.value = value
	}
}
