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
    
    let masterViewModel: MasterViewModel
    
    override init() {        
        masterViewModel = MasterViewModel(buttonTitle: "Show Detail")
        
        super.init()
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        return true
    }
}
