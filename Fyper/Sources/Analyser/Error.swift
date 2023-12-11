//
//  Error.swift
//  Fyper
//
//  Created by Mark Bourke on 21/02/2022.
//

import Foundation

extension Fyper {
    enum Error: Swift.Error, CustomStringConvertible {
        struct Message {
            let message: String
            let line: Int
            let column: Int
            let file: String // relative string

            ///
            /// - Parameter message:    The message to be printed to console.
            /// - Parameter line:       The line on which the error occured. Defaults to top of file when no line is specified.
            /// - Parameter column:     The column of the line on which the error occurred. Defaults to start of line.
            /// - Parameter file:       The relative path string of the file in which the error occurred.
            ///
            init(message: String, line: Int = 0, column: Int = 0, file: String) {
                self.message = message
                self.line = line
                self.column = column
                self.file = file
            }
        }

        case detail(Message)
        case basic(String)


        var description: String {
            switch self {
            case .detail(let message):
                return "\(message.file):\(message.line):\(message.column): error: \(message.message)"
            case .basic(let message):
                return "error: \(message)"
            }
        }
    }
}
