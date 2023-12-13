//
//  Component.swift
//  Fyper
//
//  Created by Mark Bourke on 14/03/2022.
//

import Foundation
import SwiftSyntax

struct Component: Equatable {
    let typename: String
	let exposedAs: String
	var isExposedAsProtocol: Bool {
		exposedAs != typename
	}
	let arguments: [Argument]
	var parameters: [Declaration] {
		arguments.filter({$0.type == .parameter}).map(\.declaration)
	}
	var dependencies: [Declaration] {
		arguments.filter({$0.type == .dependency}).map(\.declaration)
	}
	let isPublic: Bool
	let isSingleton: Bool
}
