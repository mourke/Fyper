//
//  CompileTimeTests.swift
//  CompileTimeTests
//
//  Created by Mark Bourke on 23/03/2022.
//

import XCTest
import CompileTime
import Shared
import NeedleFoundation

class TestsComponent: BootstrapComponent {
    let tracker: Tracker
    let logger: Logger
    let authenticator: Authenticator
    let factory: Factory
    let clock: Clock
    
    init(tracker: Tracker,
         logger: Logger,
         authenticator: Authenticator,
         factory: Factory,
         clock: Clock) {
        self.tracker = tracker
        self.logger = logger
        self.authenticator = authenticator
        self.factory = factory
        self.clock = clock
    }
    
    func createMasterViewModel(buttonTitle: String) -> CompileTime.MasterViewModel {
        MasterViewModel(parent: self, buttonTitle: buttonTitle)
    }
    
    func createDetailViewModel(name: String, date: Date) -> DetailViewModel {
        DetailViewModel(parent: self, name: name, date: date)
    }
    
}

class CompileTimeTests: XCTestCase {

    override func setUpWithError() throws {
        registerProviderFactories()
    }

    func testMasterViewModel_Track() throws {
        let component = TestsComponent(tracker: Tracker(),
                                      logger: Logger(),
                                      authenticator: Authenticator(),
                                      factory: Factory(),
                                      clock: Clock())
        let viewModel = component.createMasterViewModel(buttonTitle: "")
        
        viewModel.track()
    }
    
    func testDetailViewModel_Authenticate() throws {
        let component = TestsComponent(tracker: Tracker(),
                                      logger: Logger(),
                                      authenticator: Authenticator(),
                                      factory: Factory(),
                                      clock: Clock())
        let viewModel = component.createDetailViewModel(name: "", date: Date())
        
        viewModel.authenticate()
    }

}
