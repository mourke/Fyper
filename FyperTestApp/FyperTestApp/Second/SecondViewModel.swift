//
//  ChildViewModel.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 29/06/2023.
//

import Foundation
import Resolver
import Macros

protocol SecondViewModelProtocol {
    func toThirdViewController()
}

@Reusable(exposeAs: SecondViewModelProtocol)
final class SecondViewModel: SecondViewModelProtocol {

    private let logger: LoggerProtocol
    private let tracker: TrackerProtocol
    private let coordinator: SecondCoordinatorProtocol

    init(logger: LoggerProtocol, tracker: TrackerProtocol, @DependencyIgnored coordinator: SecondCoordinatorProtocol) {
        self.logger = logger
        self.tracker = tracker
        self.coordinator = coordinator
    }

    func toThirdViewController() {
        coordinator.presentThirdViewController()
    }
}
