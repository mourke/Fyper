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
    
    
    init() {
        let coffeeMaker = CoffeeMaker()
        
        Resolver.register {
            Heater() as Heatable
        }
        
        Resolver.register {
            Pump()
        }
        

        coffeeMaker.makeCoffee()
    }
}



