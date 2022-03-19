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
        
    @LazyInjected var tracker: Tracker
    let buttonTitle: String
    
    
    init(buttonTitle: String) {
        self.buttonTitle = buttonTitle
    }
    
    func detailViewModel() -> DetailViewModel {
        DetailViewModel(name: "Mark",
                             date: Date())
    }
    
    mutating func track() {
        tracker.track()
    }
}
