//
//  AppDelegate.swift
//  Normal
//
//  Created by Mark Bourke on 19/03/2022.
//

import Foundation
import UIKit
import Shared

class AppDelegate: NSObject, UIApplicationDelegate {
    
    private let tracker = Tracker()
    private let logger = Logger()
    private let authenticator = Authenticator()
    private let factory = Factory()
    private let clock = Clock()
    
    let masterViewModel: MasterViewModel
    
    override init() {
        masterViewModel = MasterViewModel(tracker: tracker,
                                         buttonTitle: "Show Detail",
                                         logger: logger,
                                         authenticator: authenticator,
                                         factory: factory,
                                          clock: clock)
        
        super.init()
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        return true
    }
}
