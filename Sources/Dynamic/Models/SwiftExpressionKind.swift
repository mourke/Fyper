//
//  SwiftExpressionKind.swift
//  Dynamic
//
//  Created by Mark Bourke on 28/02/2022.
//

import Foundation

public enum SwiftExpressionKind: String, CaseIterable {
    case call = "source.lang.swift.expr.call"
    case closure = "source.lang.swift.expr.closure"
    
}
