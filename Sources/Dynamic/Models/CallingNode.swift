//
//  CallingNode.swift
//  Dynamic
//
//  Created by Mark Bourke on 01/03/2022.
//

import Foundation

class CallingNode: Node {
    
    let typename: String
    var children: AnyCollection<Node> {
        AnyCollection(_children.map { $0 as! Node })
    }
    
    private var _children: Set<AnyHashable> = []
    weak private(set) var parent: Node?
    
    let syntaxStructure: SyntaxStructure
    
    @discardableResult
    func addChild<C: Node & Hashable>(_ child: C) -> Bool {
        return _children.insert(child).inserted
    }

    init(parent: Node?, typename: String, syntaxStructure: SyntaxStructure) {
        self.parent = parent
        self.typename = typename
        self.syntaxStructure = syntaxStructure
    }
}

extension CallingNode: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(typename)
    }

    static func == (lhs: CallingNode, rhs: CallingNode) -> Bool {
        return lhs.typename == rhs.typename
    }
}
