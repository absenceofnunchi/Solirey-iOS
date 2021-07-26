//
//  WebViewController.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-06-04.
//

import UIKit
import WebKit

class WebViewController: UIViewController {
    var urlString: String!
    private var webView: WKWebView!
    private let alert = Alerts()
    
    final override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
    }
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        configureWebView()
    }
}


// MARK: - Configure web view
extension WebViewController {
    private func configureWebView() {
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
            webView.allowsBackForwardNavigationGestures = true
        } else {
            alert.show("Error", with: "Sorry, there was an error loading the web page.", for: self) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
}

// MARK: - delegate methods
extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.hideSpinner {
            
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.showSpinner {
            
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.hideSpinner {
            
        }
    }
}
