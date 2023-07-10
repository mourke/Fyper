//
//  ChildViewController.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 29/06/2023.
//

import UIKit
import WebKit

final class ThirdViewController: UIViewController {

    private let webView = WKWebView(frame: .null, configuration: WKWebViewConfiguration())
    private let viewModel: ThirdViewModelProtocol

    init(viewModel: ThirdViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: ThirdViewController.self), bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        viewModel.authenticate(webView: webView)
    }
}
