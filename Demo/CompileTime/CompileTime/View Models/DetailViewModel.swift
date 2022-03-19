//
//  DetailViewModel.swift
//  Normal
//
//  Created by Mark Bourke on 18/03/2022.
//

import Foundation
import Shared
import NeedleFoundation

protocol DetailViewModelDependency: Dependency {
    var tracker: Tracker { get }
    var logger: Logger { get }
    var authenticator: Authenticator { get }
    var factory: Factory { get }
    var clock: Clock { get }
}

class DetailViewModel: Component<DetailViewModelDependency> {
    let name: String
    let date: Date
    
    init(parent: Scope, name: String, date: Date) {
        self.name = name
        self.date = date
        
        super.init(parent: parent)
    }
    
    func authenticate() {
        dependency.authenticator.authenticate()
        dependency.clock.tick()
        dependency.factory.create()
        dependency.logger.log(event: "Authenticate Event")
    }
}
