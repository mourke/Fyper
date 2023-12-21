//
//  ViewModel.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 29/06/2023.
//

import Foundation
import Macros
import Combine

protocol FirstViewModelProtocol {
    func toSecondViewController()
}

@Reusable
final actor FirstViewModel<S: Scheduler>: FirstViewModelProtocol {

    private let logger: LoggerProtocol
    private let coordinator: FirstCoordinatorProtocol
	private let scheduler: S

	@Inject
    init(
		logger: LoggerProtocol,
		@DependencyIgnored coordinator: FirstCoordinatorProtocol,
		@DependencyIgnored scheduler: S = DispatchQueue.main
	) {
        self.logger = logger
        self.coordinator = coordinator
		self.scheduler = scheduler
    }

	init() {
		preconditionFailure()
	}

	nonisolated func toSecondViewController() {
        coordinator.presentSecondViewController()
    }
}
