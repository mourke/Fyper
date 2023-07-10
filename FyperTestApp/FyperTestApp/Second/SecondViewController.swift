//
//  ChildViewController.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 29/06/2023.
//

import UIKit

final class SecondViewController: UIViewController {

    private let viewModel: SecondViewModelProtocol

    init(viewModel: SecondViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: SecondViewController.self), bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        viewModel.toThirdViewController()
    }

}
