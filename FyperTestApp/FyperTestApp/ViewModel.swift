//
//  ViewModel.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 29/06/2023.
//

import Foundation
import Resolver

final class ViewModel {

    @Register var logger: LoggerProtocol = Logger()

    func myFunc() {
        myInferredVar(ChildViewModel())
    }

    func myInferredVar(_ vm: ChildViewModel) {

    }
}
