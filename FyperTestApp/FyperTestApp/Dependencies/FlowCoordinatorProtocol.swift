//
//  FlowCoordinatorProtocol.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 18/12/2023.
//

import Foundation
import UIKit

protocol FlowCoordinatorProtocol {
	/* unowned */ var presentingViewController: UIViewController { get }
	func startFlow()
}
