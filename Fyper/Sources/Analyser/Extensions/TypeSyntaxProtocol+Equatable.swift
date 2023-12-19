//
//  TypeSyntaxProtocol+Equatable.swift
//  Fyper
//
//  Created by Mark Bourke on 19/12/2023.
//

import Foundation
import SwiftSyntax

extension TypeSyntaxProtocol {
	func isEqual(to other: TypeSyntaxProtocol) -> Bool {
		return trimmedDescription == other.trimmedDescription
	}
}
