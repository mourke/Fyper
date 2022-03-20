//
//  MasterViewModel.swift
//  Normal
//
//  Created by Mark Bourke on 18/03/2022.
//

import Foundation
import Shared
import Resolver

struct MasterViewModel {
        
    let tracker: Tracker
    let buttonTitle: String
    
    // fyper: @SafeInject(arguments: 1)
    init(tracker: Tracker, buttonTitle: String) {
        self.tracker = tracker
        self.buttonTitle = buttonTitle
    }
    
    func detailViewModel() -> DetailViewModel {
        DetailViewModel(name: "Mark", date: Date())
    }
    
    mutating func track() {
        tracker.track()
    }
}
