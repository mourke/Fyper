//
//  DetailViewModel.swift
//  Normal
//
//  Created by Mark Bourke on 18/03/2022.
//

import Foundation
import Shared
import Resolver

struct DetailViewModel {
    
    @LazyInjected var logger: Logger
    @LazyInjected var authenticator: Authenticator
    @LazyInjected var factory: Factory
    @LazyInjected var clock: Clock
    let name: String
    let date: Date
    
    init(name: String, date: Date) {
        self.name = name
        self.date = date
    }
    
    mutating func authenticate() {
        authenticator.authenticate()
        clock.tick()
        factory.create()
        logger.log(event: "Authenticate Event")
    }
}
