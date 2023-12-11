//
//  Component.swift
//  Fyper
//
//  Created by Mark Bourke on 14/03/2022.
//

import Foundation
import SwiftSyntax

struct Component: Hashable {
    let typename: String
	let exposedAs: String
    let parameters: FunctionParameterListSyntax
    let dependencies: FunctionParameterListSyntax
	let isPublic: Bool
	let isSingleton: Bool

    static func == (lhs: Component, rhs: Component) -> Bool {
        lhs.typename == rhs.typename
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(typename)
    }
}
