//
//  Coordinator.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 10/07/2023.
//

import UIKit
import Macros

protocol SecondCoordinatorProtocol: FlowCoordinatorProtocol {
    func presentThirdViewController()
}

@Reusable(exposeAs: FlowCoordinatorProtocol)
final class SecondCoordinator: SecondCoordinatorProtocol, FlowCoordinatorProtocol {

	private (set) unowned var presentingViewController: UIViewController
	private let container: FyperTestAppContainer

	@Inject
	init(
		container: FyperTestAppContainer,
		@DependencyIgnored presentingViewController: UIViewController
	) {
		self.container = container
		self.presentingViewController = presentingViewController
	}

	func startFlow() {
		let viewModel = container.buildSecondViewModel(coordinator: self)
		let viewController = SecondViewController(viewModel: viewModel)

		presentingViewController.present(viewController, animated: true)
	}

	func presentThirdViewController() {
		guard let presentingViewController = presentingViewController.presentedViewController else {
			fatalError()
		}
		let thirdCoordinator = container.buildThirdCoordinator(presentingViewController: presentingViewController)
		thirdCoordinator.startFlow()
	}
}
