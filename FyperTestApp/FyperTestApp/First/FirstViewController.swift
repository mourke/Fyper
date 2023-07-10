//
//  ViewController.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 14/06/2023.
//

import UIKit

final class FirstViewController: UIViewController {

    private let viewModel: FirstViewModelProtocol

    init(viewModel: FirstViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: FirstViewController.self), bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        viewModel.toSecondViewController()
    }
}

