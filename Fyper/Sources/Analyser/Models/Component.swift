//
//  Component.swift
//  Fyper
//
//  Created by Mark Bourke on 14/03/2022.
//

import Foundation
import SwiftSyntax

/// A component is the name of any data structure that wants to participate in dependency injection.
struct Component: Equatable {

	/// The simple type of the component. This will probably break if applied to a generic class.
    let typename: String

	/// The protocol that the Component is exposed as in the generated container. If this is the same as `typename`, no abstraction should occur.
	let exposedAs: String

	/// If the type has been exposed as a protocol. We use this to optionally insert the `some` and `any` keywords before the function return clause.
	var isExposedAsProtocol: Bool {
		// @mbourke: we know that if they are different it has to be a protocol as ensured by the macro
		exposedAs != typename
	}

	/// All of the arguments, in order, that the initializer of the type takes.
	let arguments: [Argument]

	/// A parameter is a value injected into a class that changes every time the class is instantiated. E.g. the title of a ViewController
	var parameters: [Declaration] {
		arguments.filter({$0.type == .parameter}).map(\.declaration)
	}

	/// A dependency is a value injected into a class that usually outlives the lifetime of the class and can come from other modules. E.g. a logger
	var dependencies: [Declaration] {
		arguments.filter({$0.type == .dependency}).map(\.declaration)
	}

	/// If the builder function of the Component should be marked as public inside the generated Container.
	let isPublic: Bool

	/// A singleton will live for the duration of the Container as opposed to its lifetime being tied to the Component's. E.g. you might want
	/// to share a single repository instance between two view models so it would be a singleton, whereas you would not want to share a monitor
	/// between two view models so it would just be a reusable.
	let isSingleton: Bool
}
