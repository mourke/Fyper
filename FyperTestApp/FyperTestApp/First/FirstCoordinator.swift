//
//  Coordinator.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 10/07/2023.
//

import UIKit
import Resolver
import Macros

protocol FirstCoordinatorProtocol {
    func presentSecondViewController()
}

@Reusable(exposeAs: FirstCoordinatorProtocol, scope: .public)
final class FirstCoordinator: FirstCoordinatorProtocol {

    private weak var rootViewController: UIViewController?

    func presentSecondViewController() {
        let secondCoordinator = SecondCoordinator(presentingViewController: rootViewController!)
        secondCoordinator.startFlow()
    }
}
