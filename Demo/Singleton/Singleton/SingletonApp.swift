//
//  SingletonApp.swift
//  Singleton
//
//  Created by Mark Bourke on 23/03/2022.
//

import SwiftUI

@main
struct SingletonApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    
    var body: some Scene {
        WindowGroup {
            MasterView(viewModel: appDelegate.masterViewModel)
        }
    }
}
