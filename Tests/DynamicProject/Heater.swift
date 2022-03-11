//
//  Heater.swift
//  DynamicProject
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation

protocol Heatable {
    
}

class Heater: Heatable {
    
    func heat() {
        print("Heating water")
    }
}

