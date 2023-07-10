//
//  Coordinator.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 10/07/2023.
//

import UIKit

protocol ThirdCoordinatorProtocol {

}

final class ThirdCoordinator: ThirdCoordinatorProtocol {

    private weak var presentingViewController: UIViewController?

    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }

    func startFlow() {
        let viewModel = ThirdViewModel(coordinator: self)
        let viewController = ThirdViewController(viewModel: viewModel)

        presentingViewController?.present(viewController, animated: true)
    }
}
