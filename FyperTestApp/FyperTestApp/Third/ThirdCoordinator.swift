//
//  Coordinator.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 10/07/2023.
//

import UIKit
import Macros

protocol ThirdCoordinatorProtocol: FlowCoordinatorProtocol {
}

@Reusable(exposeAs: FlowCoordinatorProtocol)
final class ThirdCoordinator: ThirdCoordinatorProtocol, FlowCoordinatorProtocol {

	private let container: FyperTestAppContainer
    private (set) unowned var presentingViewController: UIViewController

	@Inject
	init(
		container: FyperTestAppContainer,
		@DependencyIgnored presentingViewController: UIViewController
	) {
		self.container = container
        self.presentingViewController = presentingViewController
    }

    func startFlow() {
		let viewModel = container.buildThirdViewModel(coordinator: self)
        let viewController = ThirdViewController(viewModel: viewModel)

        presentingViewController.present(viewController, animated: true)
    }
}
