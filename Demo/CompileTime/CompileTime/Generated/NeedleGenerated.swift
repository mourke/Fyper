

import Foundation
import NeedleFoundation
import Shared
import UIKit

// swiftlint:disable unused_declaration
private let needleDependenciesHash : String? = nil

// MARK: - Registration

public func registerProviderFactories() {
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->MainComponent->MasterViewModel") { component in
        return MasterViewModelDependency45c11aa0fd8d61d0bd7dProvider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->MainComponent->MasterViewModel->DetailViewModel") { component in
        return DetailViewModelDependencydfa60aa34a2de0b485d1Provider(component: component)
    }
    __DependencyProviderRegistry.instance.registerDependencyProviderFactory(for: "^->MainComponent") { component in
        return EmptyDependencyProvider(component: component)
    }
    
}

// MARK: - Providers

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
