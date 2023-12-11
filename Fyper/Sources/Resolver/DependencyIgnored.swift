//
//  Register.swift
//
//
//  Created by Mark Bourke on 28/06/2023.
//

import Foundation

/// Marks initialiser parameter as not a dependency.
@propertyWrapper public struct DependencyIgnored<Dependency> {

	public init(wrappedValue: Dependency) {
		self.wrappedValue = wrappedValue
	}

	public let wrappedValue: Dependency
}
