//
//  main.swift
//  DynamicProject
//
//  Created by Mark Bourke on 26/01/2022.
//

import Foundation
import Resolver

@main
class Main {
    
    
    static func main() {
        Resolver.register {
            Heater()
        }

        Resolver.register {
            Pump()
        }
        
        let coffeeMaker = CoffeeMaker.init()
        
        coffeeMaker.makeCoffee()
    }
}



