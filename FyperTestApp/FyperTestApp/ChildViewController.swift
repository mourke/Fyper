//
//  ChildViewController.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 29/06/2023.
//

import UIKit

class ChildViewController: UIViewController {

    let viewModel: ChildViewModel

    init(viewModel: ChildViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
