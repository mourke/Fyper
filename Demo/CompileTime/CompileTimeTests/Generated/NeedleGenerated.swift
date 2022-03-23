

import CompileTime
import Foundation
import NeedleFoundation
import Shared
import UIKit
import XCTest

// swiftlint:disable unused_declaration
private let needleDependenciesHash : String? = nil

// MARK: - Registration

public func registerProviderFactories() {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->TestsComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->TestsComponent->MasterViewModel") { component in
        return MasterViewModelDependencyc8813fca4604366045baProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->MainComponent->MasterViewModel") { component in
        return MasterViewModelDependency45c11aa0fd8d61d0bd7dProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->TestsComponent->DetailViewModel") { component in
        return DetailViewModelDependencyc124e8ed13b9a3400d1eProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->TestsComponent->MasterViewModel->DetailViewModel") { component in
        return DetailViewModelDependency5826ca31e12a5b4fadc2Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->MainComponent->MasterViewModel->DetailViewModel") { component in
        return DetailViewModelDependencydfa60aa34a2de0b485d1Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->MainComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    
}

// MARK: - Providers

private class MasterViewModelDependencyc8813fca4604366045baBaseProvider: MasterViewModelDependency {
    var tracker: Tracker {
        return testsComponent.tracker
    }
    private let testsComponent: TestsComponent
    init(testsComponent: TestsComponent) {
        self.testsComponent = testsComponent
    }
}
/// ^->TestsComponent->MasterViewModel
private class MasterViewModelDependencyc8813fca4604366045baProvider: MasterViewModelDependencyc8813fca4604366045baBaseProvider {
    init(component: NeedleFoundation.Scope) {
        super.init(testsComponent: component.parent as! TestsComponent)
    }
}
private class MasterViewModelDependency45c11aa0fd8d61d0bd7dBaseProvider: MasterViewModelDependency {
    var tracker: Tracker {
        return mainComponent.tracker
    }
    private let mainComponent: MainComponent
    init(mainComponent: MainComponent) {
        self.mainComponent = mainComponent
    }
}
/// ^->MainComponent->MasterViewModel
private class MasterViewModelDependency45c11aa0fd8d61d0bd7dProvider: MasterViewModelDependency45c11aa0fd8d61d0bd7dBaseProvider {
    init(component: NeedleFoundation.Scope) {
        super.init(mainComponent: component.parent as! MainComponent)
    }
}
private class DetailViewModelDependencyc124e8ed13b9a3400d1eBaseProvider: DetailViewModelDependency {
    var tracker: Tracker {
        return testsComponent.tracker
    }
    var logger: Logger {
        return testsComponent.logger
    }
    var authenticator: Authenticator {
        return testsComponent.authenticator
    }
    var factory: Factory {
        return testsComponent.factory
    }
    var clock: Clock {
        return testsComponent.clock
    }
    private let testsComponent: TestsComponent
    init(testsComponent: TestsComponent) {
        self.testsComponent = testsComponent
    }
}
/// ^->TestsComponent->DetailViewModel
private class DetailViewModelDependencyc124e8ed13b9a3400d1eProvider: DetailViewModelDependencyc124e8ed13b9a3400d1eBaseProvider {
    init(component: NeedleFoundation.Scope) {
        super.init(testsComponent: component.parent as! TestsComponent)
    }
}
/// ^->TestsComponent->MasterViewModel->DetailViewModel
private class DetailViewModelDependency5826ca31e12a5b4fadc2Provider: DetailViewModelDependencyc124e8ed13b9a3400d1eBaseProvider {
    init(component: NeedleFoundation.Scope) {
        super.init(testsComponent: component.parent.parent as! TestsComponent)
    }
}
private class DetailViewModelDependencydfa60aa34a2de0b485d1BaseProvider: DetailViewModelDependency {
    var tracker: Tracker {
        return mainComponent.tracker
    }
    var logger: Logger {
        return mainComponent.logger
    }
    var authenticator: Authenticator {
        return mainComponent.authenticator
    }
    var factory: Factory {
        return mainComponent.factory
    }
    var clock: Clock {
        return mainComponent.clock
    }
    private let mainComponent: MainComponent
    init(mainComponent: MainComponent) {
        self.mainComponent = mainComponent
    }
}
/// ^->MainComponent->MasterViewModel->DetailViewModel
private class DetailViewModelDependencydfa60aa34a2de0b485d1Provider: DetailViewModelDependencydfa60aa34a2de0b485d1BaseProvider {
    init(component: NeedleFoundation.Scope) {
        super.init(mainComponent: component.parent.parent as! MainComponent)
    }
}
