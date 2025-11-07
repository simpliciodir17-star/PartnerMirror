import UIKit
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate {
  private var webView: WKWebView!
  private let partnerURL = URL(string: "https://partner.obynexbroker.com/partner")!

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let config = WKWebViewConfiguration()
    config.websiteDataStore = .default()           // cookies/localStorage persistentes
    config.preferences.javaScriptEnabled = true    // JS ligado

    webView = WKWebView(frame: .zero, configuration: config)
    webView.navigationDelegate = self
    webView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(webView)
    NSLayoutConstraint.activate([
      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.topAnchor.constraint(equalTo: view.topAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    var req = URLRequest(url: partnerURL)
    req.cachePolicy = .reloadIgnoringLocalCacheData
    webView.load(req)
  }
}
