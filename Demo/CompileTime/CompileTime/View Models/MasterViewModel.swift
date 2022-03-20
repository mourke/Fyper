//
//  MasterViewModel.swift
//  Normal
//
//  Created by Mark Bourke on 18/03/2022.
//

import Foundation
import Shared
import NeedleFoundation

protocol MasterViewModelDependency: Dependency {
    var tracker: Tracker { get }
}

class MasterViewModel: Component<MasterViewModelDependency> {
    let buttonTitle: String
    
    
    init(parent: Scope, buttonTitle: String) {
        self.buttonTitle = buttonTitle
        super.init(parent: parent)
    }
    
    func detailViewModel() -> DetailViewModel {
        DetailViewModel(parent: self, name: "Mark", date: Date())
    }
    
    func track() {
        dependency.tracker.track()
    }
}
