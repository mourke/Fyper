//
//  InitialNode.swift
//  Dynamic
//
//  Created by Mark Bourke on 01/03/2022.
//

import Foundation
import SwiftSyntax

final class InitialNode: Node {
    let initializer: InjectableInitializer
    
    var children: AnyCollection<Node> {
        AnyCollection(_children.map { $0 as! Node })
    }
    
    private var _children: Set<AnyHashable> = []
    weak private(set) var parent: Node?
    
    var enclosingDataStructure: DataStructureDeclSyntaxProtocol {
        initializer.rootDataStructureSyntax
    }

    @discardableResult
    func addChild<C: Node & Hashable>(_ child: C) -> Bool {
        return _children.insert(child).inserted
    }
    
    init(initializer: InjectableInitializer) {
        self.initializer = initializer
    }
    
}

extension InitialNode: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(initializer)
    }

    static func == (lhs: InitialNode, rhs: InitialNode) -> Bool {
        return lhs.initializer == rhs.initializer
    }
}
