//
//  WebViewAuthenticator.swift
//  FyperTestApp
//
//  Created by Mark Bourke on 29/06/2023.
//

import Foundation
import WebKit

public protocol WebViewAuthenticatorProtocol {
    func authenticate(_ webView: WKWebView) -> Bool
}

final class WebViewAuthenticator: WebViewAuthenticatorProtocol {

    func authenticate(_ webView: WKWebView) -> Bool {
        print("It authenticates!")
        return true
    }
}
