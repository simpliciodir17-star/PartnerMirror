import UIKit
import WebKit

final class WebViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
  private var webView: WKWebView!
  // Endereço correto do painel (raiz, sem /partner)
  private let partnerURL = URL(string: "https://partner.obynexbroker.com/")!
  private var lastTokenSnippet: String?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    // JS para capturar token (local/session storage ou cookie)
    let tokenJS = """
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
            } catch(e) {}
        }
        window.addEventListener('load', findToken);
        setInterval(findToken, 3000);
    })();
    """

    let userContent = WKUserContentController()
    userContent.addUserScript(WKUserScript(source: tokenJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
    userContent.add(self, name: "nativeHandler")

    let config = WKWebViewConfiguration()
    config.websiteDataStore = .default()          // cookies/localStorage persistentes
    config.preferences.javaScriptEnabled = true
    config.userContentController = userContent

    let wv = WKWebView(frame: .zero, configuration: config)
    self.webView = wv
    wv.navigationDelegate = self
    wv.uiDelegate = self
    wv.isOpaque = false
    wv.backgroundColor = .systemBackground
    wv.scrollView.backgroundColor = .systemBackground
    wv.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(wv)
    NSLayoutConstraint.activate([
      wv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      wv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      wv.topAnchor.constraint(equalTo: view.topAnchor),
      wv.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    var req = URLRequest(url: partnerURL)
    req.cachePolicy = .reloadIgnoringLocalCacheData
    wv.load(req)
  }

  // Recebe token do JS
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard message.name == "nativeHandler",
          let body = message.body as? [String: Any],
          let type = body["type"] as? String, type == "auth_token",
          let token = body["token"] as? String, !token.isEmpty else { return }

    let snippet = "\(token.prefix(4))…\(token.suffix(4))"
    if snippet != lastTokenSnippet {
      lastTokenSnippet = snippet
      let alert = UIAlertController(title: "Token capturado", message: snippet, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      present(alert, animated: true)
    }
  }

  // Corrige target=_blank abrindo na mesma WebView
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
