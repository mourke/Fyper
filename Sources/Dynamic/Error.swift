//
//  Error.swift
//  Dynamic
//
//  Created by Mark Bourke on 21/02/2022.
//

import Foundation

extension Fyper {
    enum Error: Swift.Error, CustomStringConvertible {
        struct Message {
            let message: String
            let line: Int
            let file: String // relative string
            
            ///
            /// - Parameter message:    The message to be printed to console.
            /// - Parameter line:       The line on which the error occured. Defaults to top of file when no line is specified.
            /// - Parameter file:       The relative path string of the file in which the error occurred.
            ///
            init(message: String, line: Int = 0, file: String) {
                self.message = message
                self.line = line
                self.file = file
            }
        }
        
        case graphError(Message)
        case parseError(Message)
        case internalError(String)
        
        
        var description: String {
            switch self {
            case .graphError(let message):
                return "\(message.file):\(message.line): error: \(message.message)"
            case .parseError(let message):
                return "\(message.file):\(message.line): error: \(message.message)"
            case .internalError(let message):
                return "error: \(message)"
            }
        }
    }
}
