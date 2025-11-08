import UIKit
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
  private var webView: WKWebView!
  private let partnerURL = URL(string: "https://partner.obynexbroker.com/")!

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    let cfg = WKWebViewConfiguration()
    cfg.websiteDataStore = .default()
    cfg.preferences.javaScriptEnabled = true

    let wv = WKWebView(frame: .zero, configuration: cfg)
    wv.navigationDelegate = self
    wv.uiDelegate = self
    wv.isOpaque = false
    wv.backgroundColor = .white
    wv.scrollView.backgroundColor = .white
    wv.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(wv)
    NSLayoutConstraint.activate([
      wv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      wv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      wv.topAnchor.constraint(equalTo: view.topAnchor),
      wv.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
    self.webView = wv

    // 1) prova de vida: HTML local (evita parecer “preto”)
    webView.loadHTMLString("<html><body style='font:16px -apple-system;background:#fff;display:flex;align-items:center;justify-content:center;height:100vh'>WKWebView OK…</body></html>", baseURL: nil)

    // 2) navega pro painel
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      guard let self else { return }
      var req = URLRequest(url: self.partnerURL)
      req.cachePolicy = .reloadIgnoringLocalCacheData
      self.webView.load(req)
    }
  }

  // abre target=_blank na mesma webview
  func webView(_ webView: WKWebView,
               createWebViewWith configuration: WKWebViewConfiguration,
               for navigationAction: WKNavigationAction,
               windowFeatures: WKWindowFeatures) -> WKWebView? {
    if navigationAction.targetFrame == nil {
      webView.load(navigationAction.request)
    }
    return nil
  }
}
