//
//  Coordinator.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 10/07/2023.
//

import UIKit
import Resolver

protocol SecondCoordinatorProtocol {
    func presentThirdViewController()
}

final class SecondCoordinator: SecondCoordinatorProtocol {

    private weak var presentingViewController: UIViewController?

    @Register var webViewAuthenticator: WebViewAuthenticatorProtocol = WebViewAuthenticator()

    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }

    func startFlow() {
        let viewModel = SecondViewModel(coordinator: self)
        let viewController = SecondViewController(viewModel: viewModel)

        presentingViewController?.present(viewController, animated: true)
    }

    func presentThirdViewController() {
        guard let presentingViewController = presentingViewController?.presentedViewController else { return }
        let thirdCoordinator = ThirdCoordinator(presentingViewController: presentingViewController)
        thirdCoordinator.startFlow()
    }
}
