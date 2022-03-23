//
//  MasterViewModel.swift
//  Normal
//
//  Created by Mark Bourke on 18/03/2022.
//

import Foundation
import Shared

public struct MasterViewModel {
    
    let buttonTitle: String
    let tracker: Tracker
    
    let logger: Logger
    let authenticator: Authenticator
    let factory: Factory
    let clock: Clock
    
    
    public init(tracker: Tracker, buttonTitle: String, logger: Logger, authenticator: Authenticator, factory: Factory, clock: Clock) {
        self.logger = logger
        self.buttonTitle = buttonTitle
        self.tracker = tracker
        self.authenticator = authenticator
        self.factory = factory
        self.clock = clock
    }
    
    func detailViewModel() -> DetailViewModel {
        DetailViewModel(logger: logger,
                        authenticator: authenticator,
                        factory: factory,
                        clock: clock,
                        name: "Mark",
                        date: Date())
    }
    
    public func track() {
        tracker.track()
    }
}
