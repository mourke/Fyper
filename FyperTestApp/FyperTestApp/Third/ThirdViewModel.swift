//
//  ChildViewModel.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 29/06/2023.
//

import Foundation
import Resolver
import Macros
import WebKit

protocol ThirdViewModelProtocol {
    func authenticate(webView: WKWebView)
}

final class ThirdViewModel: ThirdViewModelProtocol {

    private let tracker: TrackerProtocol
    private let authenticator: WebViewAuthenticatorProtocol
    private let coordinator: ThirdCoordinatorProtocol

    @Inject(args: 2)
    init(
        tracker: TrackerProtocol,
        authenticator: WebViewAuthenticatorProtocol,
        coordinator: ThirdCoordinatorProtocol
    ) {
        self.tracker = tracker
        self.authenticator = authenticator
        self.coordinator = coordinator
    }

    func authenticate(webView: WKWebView) {
        if authenticator.authenticate(webView) {
            tracker.track()
        }
    }
}
