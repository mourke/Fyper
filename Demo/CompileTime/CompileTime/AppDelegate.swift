//
//  AppDelegate.swift
//  Normal
//
//  Created by Mark Bourke on 19/03/2022.
//

import Foundation
import UIKit
import Shared
import NeedleFoundation

class MainComponent: BootstrapComponent {
    var tracker: Tracker {
        shared {
            Tracker()
        }
    }
    var logger: Logger {
        shared {
            Logger()
        }
    }
    var authenticator: Authenticator {
        shared {
            Authenticator()
        }
    }
    var factory: Factory {
        shared {
            Factory()
        }
    }
    var clock: Clock {
        shared {
            Clock()
        }
    }
    
    var masterViewModel: MasterViewModel!
    
    override init() {
        super.init()
        masterViewModel = MasterViewModel(parent: self,
                                               buttonTitle: "Show Detail")
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
    private let mainComponent: MainComponent
    
    var masterViewModel: MasterViewModel {
        mainComponent.masterViewModel
    }
    
    override init() {
        registerProviderFactories()
        
        mainComponent = MainComponent()
        
        super.init()
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        return true
    }
}
