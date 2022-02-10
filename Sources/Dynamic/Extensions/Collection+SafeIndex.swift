//
//  Collection+SafeIndex.swift
//  DynamicProject
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation

public extension RandomAccessCollection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        guard index >= startIndex, index < endIndex else {
            return nil
        }
        return self[index]
    }
}
