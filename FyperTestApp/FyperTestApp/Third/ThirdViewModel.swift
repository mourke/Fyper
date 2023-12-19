//
//  ChildViewModel.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 29/06/2023.
//

import Foundation
import Macros
import WebKit

protocol ThirdViewModelProtocol {
    func authenticate(webView: WKWebView)
}

@Reusable(exposeAs: ThirdViewModelProtocol)
final class ThirdViewModel: ThirdViewModelProtocol {

    private let tracker: TrackerProtocol
    private let authenticator: WebViewAuthenticatorProtocol
    private let coordinator: ThirdCoordinatorProtocol

	@Inject
    init(
        tracker: TrackerProtocol,
        authenticator: WebViewAuthenticatorProtocol,
		@DependencyIgnored coordinator: ThirdCoordinatorProtocol
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
