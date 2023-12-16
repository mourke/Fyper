//
//  Logger.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 29/06/2023.
//

import Foundation

public protocol LoggerProtocol {
    func log()
}

final class Logger: LoggerProtocol {

    func log() {
        print("It logs!")
    }
}
