//
//  DetailViewModel.swift
//  Normal
//
//  Created by Mark Bourke on 18/03/2022.
//

import Foundation
import Shared
import Resolver

public struct DetailViewModel {
        
    let logger: Logger
    let authenticator: Authenticator
    let factory: Factory
    let clock: Clock
    let name: String
    let date: Date
    
    // fyper: @SafeInject(arguments: 4)
    public init(logger: Logger, authenticator: Authenticator, factory: Factory, clock: Clock, name: String, date: Date) {
        self.logger = logger
        self.authenticator = authenticator
        self.factory = factory
        self.clock = clock
        self.name = name
        self.date = date
    }
    
    public mutating func authenticate() {
        authenticator.authenticate()
        clock.tick()
        factory.create()
        logger.log(event: "Authenticate Event")
    }
}
