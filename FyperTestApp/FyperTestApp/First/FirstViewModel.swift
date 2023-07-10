//
//  ViewModel.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 29/06/2023.
//

import Foundation
import Resolver
import Macros

protocol FirstViewModelProtocol {
    func toSecondViewController()
}

final class FirstViewModel: FirstViewModelProtocol {

    private let logger: LoggerProtocol
    private let coordinator: FirstCoordinatorProtocol

    @Inject(args: 1)
    init(logger: LoggerProtocol, coordinator: FirstCoordinatorProtocol) {
        self.logger = logger
        self.coordinator = coordinator
    }

    func toSecondViewController() {
        coordinator.presentSecondViewController()
    }
}
