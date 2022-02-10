//
//  Generator.swift
//  Dynamic
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation

let code = """
extension CoffeeMaker {
    
    convenience init() {
        self.init(pump: Pump(), heater: Heater())
    }
}
"""

struct Generator {
    
    let logger: Logger
    let options: Options
    
    
    func generate() throws {
        let filePath = options.outputDirectoryPath + "/FyperGenerated.swift"
        try code.write(toFile: filePath, atomically: true, encoding: .ascii)
    }
}
