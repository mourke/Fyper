//
//  String+Extension.swift
//  Fyper
//
//  Created by Mark Bourke on 11/12/2023.
//

import Foundation

extension String {
	var lowercasingFirst: String {
		return prefix(1).lowercased() + dropFirst()
	}
}
