//
//  Logger.swift
//  Dynamic
//
//  Created by Mark Bourke on 10/02/2022.
//

import Foundation

struct Logger {
    
    enum Kind {
        case error
        case info
        case debug
    }
    
    private let verboseLoggingEnabled: Bool
    
    init(verboseLogging: Bool) {
        verboseLoggingEnabled = verboseLogging
    }
    
    func log(_ message: String, kind: Kind) {
        switch kind {
        case .error:
            FileHandle.standardError.write(message.data(using: .ascii)!)
        case .debug:
            guard verboseLoggingEnabled else { break }
            fallthrough
        case .info:
            print(message)
        }
    }
}
