import UIKit
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
  private var webView: WKWebView!
  private let partnerURL = URL(string: "https://partner.obynexbroker.com/")!
  private var lastTokenSnippet: String?
  private let loadingLabel: UILabel = {
    let l = UILabel()
    l.text = "Carregando…"
    l.textAlignment = .center
    l.font = .systemFont(ofSize: 16, weight: .medium)
    l.translatesAutoresizingMaskIntoConstraints = false
    l.isHidden = false
    return l
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white  // força claro no preview

    // 1) Controller de scripts + JS de captura do token
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
    userContent.add(self, name: "nativeHandler")

    // 2) WebView persistente + UA de Safari iOS
    let config = WKWebViewConfiguration()
    config.websiteDataStore = .default()
    config.preferences.javaScriptEnabled = true
    config.userContentController = userContent

    webView = WKWebView(frame: .zero, configuration: config)
    webView.navigationDelegate = self
    webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
    webView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(webView)
    view.addSubview(loadingLabel)

    NSLayoutConstraint.activate([
      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.topAnchor.constraint(equalTo: view.topAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      loadingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])

    var req = URLRequest(url: partnerURL)
    req.cachePolicy = .reloadIgnoringLocalCacheData
    webView.load(req)
  }

  // Recebe {type:'auth_token', token:'...'} do JS
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard message.name == "nativeHandler",
          let body = message.body as? [String: Any],
          (body["type"] as? String) == "auth_token",
          let token = body["token"] as? String,
          !token.isEmpty else { return }

    let snippet = "\(token.prefix(4))…\(token.suffix(4))"
    guard snippet != lastTokenSnippet else { return }
    lastTokenSnippet = snippet

    DispatchQueue.main.async {
      let a = UIAlertController(title: "Token capturado", message: snippet, preferredStyle: .alert)
      a.addAction(UIAlertAction(title: "OK", style: .default))
      self.present(a, animated: true)
    }
  }

  // ===== DEBUG de navegação =====
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if let u = navigationAction.request.url?.absoluteString { print("[NAV] \(u)") }
    decisionHandler(.allow)
  }

  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    loadingLabel.isHidden = false
    print("[LOAD] start \(webView.url?.absoluteString ?? "")")
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    loadingLabel.isHidden = true
    print("[LOAD] finish \(webView.url?.absoluteString ?? "")")
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    loadingLabel.isHidden = true
    let nsErr = error as NSError
    print("[LOAD][FAIL] \(nsErr.domain) \(nsErr.code) \(nsErr.localizedDescription)")
    let msg = "Erro ao abrir: \(nsErr.localizedDescription)\n(\(nsErr.domain)#\(nsErr.code))"
    let a = UIAlertController(title: "Falha ao carregar", message: msg, preferredStyle: .alert)
    a.addAction(UIAlertAction(title: "OK", style: .default))
    present(a, animated: true)
  }

  deinit {
    webView?.configuration.userContentController.removeScriptMessageHandler(forName: "nativeHandler")
  }
}
