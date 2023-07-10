//
//  Coordinator.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 10/07/2023.
//

import UIKit

protocol FirstCoordinatorProtocol {
    func presentSecondViewController()
}

final class FirstCoordinator: FirstCoordinatorProtocol {

    private weak var rootViewController: UIViewController?


    func instantiateRoot() -> UIViewController {
        let viewModel = FirstViewModel(coordinator: self)
        let viewController = FirstViewController(viewModel: viewModel)
        rootViewController = viewController
        return viewController
    }

    func presentSecondViewController() {
        let secondCoordinator = SecondCoordinator(presentingViewController: rootViewController!)
        secondCoordinator.startFlow()
    }
}
