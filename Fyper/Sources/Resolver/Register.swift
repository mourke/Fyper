//
//  File.swift
//  
//
//  Created by Mark Bourke on 28/06/2023.
//

import Foundation

/// Register dependency property wrapper
@propertyWrapper public struct Register<Dependency> {

    public init(wrappedValue: Dependency) {
        self.wrappedValue = wrappedValue
        Resolver.register { wrappedValue }
    }

    public let wrappedValue: Dependency
}
