//
//  SyntaxStructure.swift
//  Dynamic
//
//  Created by Mark Bourke on 05/02/2022.
//

import Foundation
import SourceKittenFramework

struct SyntaxStructure: Codable {
    
    let accessibility: String?
    let attribute: String?
    let attributes: [SyntaxStructure]?
    let bodyLength: Int?
    let bodyOffset: Int?
    let diagnosticStage: String?
    let elements: [SyntaxStructure]?
    let inheritedTypes: [SyntaxStructure]?
    let kind: String?
    let length: Int?
    let name: String?
    let nameLength: Int?
    let nameOffset: Int?
    let offset: Int?
    let runtimeName: String?
    let substructure: [SyntaxStructure]?
    let typename: String?

    enum CodingKeys: String, CodingKey {
        case accessibility = "key.accessibility"
        case attribute = "key.attribute"
        case attributes = "key.attributes"
        case bodyLength = "key.bodylength"
        case bodyOffset = "key.bodyoffset"
        case diagnosticStage = "key.diagnostic_stage"
        case elements = "key.elements"
        case inheritedTypes = "key.inheritedtypes"
        case kind = "key.kind"
        case length = "key.length"
        case name = "key.name"
        case nameLength = "key.namelength"
        case nameOffset = "key.nameoffset"
        case offset = "key.offset"
        case runtimeName = "key.runtime_name"
        case substructure = "key.substructure"
        case typename = "key.typename"
    }
}
