//
//  Coordinator.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 10/07/2023.
//

import UIKit
import Macros

protocol FirstCoordinatorProtocol {
    func presentSecondViewController()

	func instantiateRoot() -> UIViewController
}

@Reusable(exposeAs: FirstCoordinatorProtocol, scope: .public)
final class FirstCoordinator: FirstCoordinatorProtocol {

    private weak var rootViewController: UIViewController?

	private let container: FyperTestAppContainer

	init(container: FyperTestAppContainer) {
		self.container = container
	}

	func instantiateRoot() -> UIViewController {
		let viewModel = container.buildFirstViewModel(coordinator: self)
		let viewController = FirstViewController(viewModel: viewModel)
		return viewController
	}

    func presentSecondViewController() {
		let secondCoordinator = container.buildSecondCoordinator()
        secondCoordinator.startFlow()
    }
}
