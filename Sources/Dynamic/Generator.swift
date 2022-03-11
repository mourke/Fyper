//
//  Generator.swift
//  Dynamic
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation

struct Generator {
    
    let logger: Logger
    let options: Options
    let graphs: [InitialNode]
    
    
    func generate() throws {
        var code = "import Resolver"
        
        for initialNode in graphs {
            let initialiser = initialNode.initializer
            
            let `extension` = """

extension \(initialiser.typename) {
    
    convenience init(\(initialiser.regularArguments.map { $0.description }.joined(separator: ", "))) {
        let pump = Resolver.resolve(Pump.self)
        let heater = Resolver.resolve(Heater.self)
        self.init(pump: pump, heater: heater)
    }
}
"""
            code += `extension`
        }
        let filePath = options.outputDirectory.path + "/FyperGenerated.swift"
        try code.write(toFile: filePath, atomically: true, encoding: .ascii)
    }
}
