//
//  Tracker.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 29/06/2023.
//

import Foundation

public protocol TrackerProtocol {
    func track()
}

final class Tracker: TrackerProtocol {

    func track() {
        print("It tracks!")
    }
}
