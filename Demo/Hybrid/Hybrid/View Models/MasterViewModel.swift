//
//  MasterViewModel.swift
//  Normal
//
//  Created by Mark Bourke on 18/03/2022.
//

import Foundation
import Shared
import Resolver

public struct MasterViewModel {
        
    let tracker: Tracker
    let buttonTitle: String
    
    // fyper: @SafeInject(arguments: 1)
    public init(tracker: Tracker, buttonTitle: String) {
        self.tracker = tracker
        self.buttonTitle = buttonTitle
    }
    
    func detailViewModel() -> DetailViewModel {
        DetailViewModel(name: "Mark", date: Date())
    }
    
    public mutating func track() {
        tracker.track()
    }
}
