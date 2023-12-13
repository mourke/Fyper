//
//  Coordinator.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 10/07/2023.
//

import UIKit
import Macros

protocol SecondCoordinatorProtocol {
    func presentThirdViewController()
	func startFlow()
}

@Reusable(exposeAs: SecondCoordinatorProtocol)
final class SecondCoordinator: SecondCoordinatorProtocol {

    private weak var presentingViewController: UIViewController?
	private let container: FyperTestAppContainer

    init(container: FyperTestAppContainer) {
		self.container = container
    }

    func startFlow() {
		let viewModel = container.buildSecondViewModel(coordinator: self)
        let viewController = SecondViewController(viewModel: viewModel)

        presentingViewController?.present(viewController, animated: true)
    }

    func presentThirdViewController() {
        guard let presentingViewController = presentingViewController?.presentedViewController else { return }
        let thirdCoordinator = ThirdCoordinator(presentingViewController: presentingViewController)
        thirdCoordinator.startFlow()
    }
}
