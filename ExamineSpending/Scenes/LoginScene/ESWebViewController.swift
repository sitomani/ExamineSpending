//
//  ESWebViewController.swift
//  ExamineSpending
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import WebKit

class ESWebViewController: UIViewController, Dismissable {
  @IBOutlet weak var webView: WKWebView?
  @IBOutlet weak var closeButton: UIButton?

  weak var dismissalDelegate: DismissalDelegate?
  var startAtUrl: URL?

  override func viewDidLoad() {
    super.viewDidLoad()

    closeButton?.layer.cornerRadius = 20.0
    closeButton?.layer.masksToBounds = true
    closeButton?.layer.shadowColor = UIColor.lightGray.cgColor

    if let url = startAtUrl {
      webView?.navigationDelegate = self
      webView?.load(URLRequest.init(url: url))
    }
  }

  @IBAction func onClose(_ sender: UIButton) {
    dismissalDelegate?.finishedShowing(viewController: self, result: nil)
  }
}

extension ESWebViewController: WKNavigationDelegate {
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    print(navigationAction.request.url?.absoluteString ?? "")
    if let url = navigationAction.request.url {
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      if let code = components?.queryItems?.first(where: {$0.name == "code"})?.value {
        decisionHandler(.cancel)
        dismissalDelegate?.finishedShowing(viewController: self, result: ["code": code])
        return
      }
    }
    decisionHandler(.allow)
  }
}
