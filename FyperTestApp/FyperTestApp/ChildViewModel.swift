//
//  ChildViewModel.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 29/06/2023.
//

import Foundation
import Resolver
import Macros

final class ChildViewModel {

    let logger: LoggerProtocol

    @Inject(args: *)
    init(logger: LoggerProtocol) {
        self.logger = logger
    }
}
