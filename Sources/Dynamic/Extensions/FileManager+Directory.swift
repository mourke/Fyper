//
//  FileManager+Directory.swift
//  Dynamic
//
//  Created by Mark Bourke on 02/02/2022.
//

import Foundation

extension FileManager {
    
    public func directoryExists(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let fileExists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        
        return isDirectory.boolValue && fileExists
    }
}
