//
//  NormalTests.swift
//  NormalTests
//
//  Created by Mark Bourke on 23/03/2022.
//

import XCTest
import Normal
import Shared

class NormalTests: XCTestCase {

    func testMasterViewModel_Track() throws {
        let viewModel = Normal.MasterViewModel(tracker: Tracker(),
                                               buttonTitle: "",
                                               logger: Logger(),
                                               authenticator: Authenticator(),
                                               factory: Factory(),
                                               clock: Clock())
        
        viewModel.track()
    }
    
    func testDetailViewModel_Authenticate() throws {
        let viewModel = Normal.DetailViewModel(logger: Logger(),
                                               authenticator: Authenticator(),
                                               factory: Factory(),
                                               clock: Clock(),
                                               name: "",
                                               date: Date())
        
        viewModel.authenticate()
    }

}
