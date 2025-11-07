import UIKit
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
  private var webView: WKWebView!
  private let partnerURL = URL(string: "https://partner.obynexbroker.com/partner")!
  private var lastTokenSnippet: String?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    // Controller de scripts + JS de captura do token
    let userContent = WKUserContentController()

    let injectedJS = #"""
    (function() {
      function findToken() {
        try {
          var token = null;
          token = window.localStorage.getItem('auth_token')
               || window.localStorage.getItem('token')
               || window.localStorage.getItem('accessToken')
               || window.sessionStorage.getItem('auth_token')
               || window.sessionStorage.getItem('token')
               || window.sessionStorage.getItem('accessToken');
          if (!token && window.__INITIAL_STATE__ && window.__INITIAL_STATE__.auth) token = window.__INITIAL_STATE__.auth.token;
          if (!token) {
            var m = document.cookie.match(/(?:^|; )(?:auth_token|token|accessToken)=([^;]+)/);
            if (m) token = decodeURIComponent(m[1]);
          }
          if (token && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.nativeHandler) {
            window.webkit.messageHandlers.nativeHandler.postMessage({type:'auth_token', token: token});
          }
        } catch(e) { /* silent */ }
      }
      window.addEventListener('load', findToken);
      setInterval(findToken, 3000);
    })();
    """#
    let userScript = WKUserScript(source: injectedJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    userContent.addUserScript(userScript)

    // Bridge JS -> nativo
    userContent.add(self, name: "nativeHandler")

    // WebView persistente
    let config = WKWebViewConfiguration()
    config.websiteDataStore = .default()
    config.preferences.javaScriptEnabled = true
    config.userContentController = userContent

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

  // WKScriptMessageHandler
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard message.name == "nativeHandler",
          let body = message.body as? [String: Any],
          (body["type"] as? String) == "auth_token",
          let token = body["token"] as? String,
          !token.isEmpty else { return }

    let snippet = "\(token.prefix(4))…\(token.suffix(4))"
    guard snippet != lastTokenSnippet else { return } // evita alerta repetindo
    lastTokenSnippet = snippet

    DispatchQueue.main.async {
      let alert = UIAlertController(title: "Token capturado", message: snippet, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      self.present(alert, animated: true)
    }
  }

  deinit {
    webView?.configuration.userContentController.removeScriptMessageHandler(forName: "nativeHandler")
  }
}
