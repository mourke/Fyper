//
//  HybridTests.swift
//  HybridTests
//
//  Created by Mark Bourke on 23/03/2022.
//

import XCTest
import Hybrid
import Shared

class HybridTests: XCTestCase {
    
    func testMasterViewModel_Track() throws {
        var viewModel = Hybrid.MasterViewModel(tracker: Tracker(), buttonTitle: "")
        
        viewModel.track()
    }
    
    func testDetailViewModel_Authenticate() throws {
        var viewModel = Hybrid.DetailViewModel(logger: Logger(),
                                               authenticator: Authenticator(),
                                               factory: Factory(),
                                               clock: Clock(),
                                               name: "",
                                               date: Date())
        
        viewModel.authenticate()
    }
}

