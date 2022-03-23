//
//  RuntimeTests.swift
//  RuntimeTests
//
//  Created by Mark Bourke on 23/03/2022.
//

import XCTest
import Runtime
import Shared
import Resolver

class RuntimeTests: XCTestCase {

    func testMasterViewModel_Track() throws {
        Resolver.register {
            Tracker()
        }
        var viewModel = Runtime.MasterViewModel(buttonTitle: "")
        
        viewModel.track()
    }
    
    func testDetailViewModel_Authenticate() throws {
        Resolver.register {
            Logger()
        }
        Resolver.register {
            Authenticator()
        }
        Resolver.register {
            Factory()
        }
        Resolver.register {
            Clock()
        }
        var viewModel = Runtime.DetailViewModel(name: "", date: Date())
        
        viewModel.authenticate()
    }

}
