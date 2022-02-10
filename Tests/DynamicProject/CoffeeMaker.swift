//
//  CoffeeMaker.swift
//  DynamicProject
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation


class CoffeeMaker {
    
    private let pump: Pump
    private let heater: Heater
    
    // fyper: @SafeInject
    init(pump: Pump, heater: Heater) {
        self.pump = pump
        self.heater = heater
    }
    
    
    
    func makeCoffee() {
        pump.start();
        heater.heat();
    }
}
