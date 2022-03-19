//
//  CompileTimeApp.swift
//  CompileTime
//
//  Created by Mark Bourke on 18/03/2022.
//

import SwiftUI

@main
struct CompileTimeApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    
    var body: some Scene {
        WindowGroup {
            MasterView(viewModel: appDelegate.masterViewModel)
        }
    }
}
