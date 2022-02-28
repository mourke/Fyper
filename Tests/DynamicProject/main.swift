//
//  main.swift
//  DynamicProject
//
//  Created by Mark Bourke on 26/01/2022.
//

import Foundation

@main
class Main {
    
    
    init() {
        let coffeeMaker = CoffeeMaker.init()
        let coffeeMaker2 = CoffeeMaker.init(pump: Pump(), heater: Heater())

        coffeeMaker.makeCoffee()
    }
}



