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
    let name: String
    let date: Date
    
    init(name: String, date: Date) {
        self.name = name
        self.date = date
    }
    
    mutating func authenticate() {
        Authenticator.shared.authenticate()
        Clock.shared.tick()
        Factory.shared.create()
        Logger.shared.log(event: "Authenticate Event")
    }
}
