import UIKit
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
  private var webView: WKWebView!
  private let partnerURL = URL(string: "https://example.com/")!
  private var lastTokenSnippet: String?

  // Banner de debug em tela (mostra URL/erros)
  private let debugBanner: UILabel = {
    let l = UILabel()
    l.backgroundColor = UIColor(white: 0.95, alpha: 1)
    l.textColor = .darkGray
    l.textAlignment = .center
    l.font = .systemFont(ofSize: 12, weight: .medium)
    l.numberOfLines = 2
    l.text = "debug: iniciando…"
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
  }()

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
    view.backgroundColor = .white // força claro no preview

    // 1) Controller de scripts + JS de captura do token
    let userContent = WKUserContentController()

    let injectedJS = #"""
    (function() {
      // Forward console.log para nativo (útil p/ debug se quiser)
      try {
        var _log = console.log;
        console.log = function() {
          try {
            var msg = Array.prototype.slice.call(arguments).join(" ");
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.nativeHandler) {
              window.webkit.messageHandlers.nativeHandler.postMessage({type:'console', msg: msg});
            }
          } catch(e) {}
          try { _log && _log.apply(console, arguments); } catch(e) {}
        };
      } catch(e) {}

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

    // 2) WebView persistente + UA Safari
    let config = WKWebViewConfiguration()
    config.websiteDataStore = .default()
    config.preferences.javaScriptEnabled = true
    config.userContentController = userContent

    let wv = WKWebView(frame: .zero, configuration: config)
    wv.navigationDelegate = self
    wv.uiDelegate = self
    wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
    wv.translatesAutoresizingMaskIntoConstraints = false
    webView = wv

    view.addSubview(webView)
    view.addSubview(debugBanner)
    view.addSubview(loadingLabel)

    let g = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      debugBanner.leadingAnchor.constraint(equalTo: g.leadingAnchor),
      debugBanner.trailingAnchor.constraint(equalTo: g.trailingAnchor),
      debugBanner.topAnchor.constraint(equalTo: g.topAnchor),
      debugBanner.heightAnchor.constraint(equalToConstant: 38),

      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.topAnchor.constraint(equalTo: debugBanner.bottomAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      loadingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])

    var req = URLRequest(url: partnerURL)
    req.cachePolicy = .reloadIgnoringLocalCacheData
    webView.load(req)
    setBanner("debug: carregando \(partnerURL.absoluteString)")
  }

  // ===== Bridge JS → nativo =====
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    if message.name == "nativeHandler" {
      if let body = message.body as? [String: Any],
         let type = body["type"] as? String {
        if type == "auth_token", let token = body["token"] as? String, !token.isEmpty {
          let snippet = "\(token.prefix(4))…\(token.suffix(4))"
          if snippet != lastTokenSnippet {
            lastTokenSnippet = snippet
            DispatchQueue.main.async {
              let a = UIAlertController(title: "Token capturado", message: snippet, preferredStyle: .alert)
              a.addAction(UIAlertAction(title: "OK", style: .default))
              self.present(a, animated: true)
            }
          }
        } else if type == "console", let msg = body["msg"] as? String {
          setBanner("console: \(msg.prefix(60))")
        }
      }
    }
  }

  // ===== Abrir target="_blank" na MESMA WebView =====
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
               decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if let url = navigationAction.request.url?.absoluteString {
      setBanner("nav: \(url.prefix(80))")
    }
    // Se a navegação pedir uma janela nova (target=_blank), carregamos aqui mesmo
    if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
      webView.load(URLRequest(url: url))
      decisionHandler(.allow)
      return
    }
    decisionHandler(.allow)
  }

  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    loadingLabel.isHidden = false
    setBanner("carregando…")
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    loadingLabel.isHidden = true
    // Força fundo branco via JS (se o site deixou o body transparente)
    let css = "document.body && (document.body.style.background = '#ffffff');"
    webView.evaluateJavaScript(css, completionHandler: nil)
    setBanner("ok: \(webView.url?.host ?? "")")
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    loadingLabel.isHidden = true
    let e = error as NSError
    setBanner("erro: \(e.domain)#\(e.code)")
    let a = UIAlertController(title: "Falha ao carregar",
                              message: "\(e.localizedDescription)\n(\(e.domain)#\(e.code))",
                              preferredStyle: .alert)
    a.addAction(UIAlertAction(title: "OK", style: .default))
    present(a, animated: true)
  }

  // WKUIDelegate — se o site tenta criar uma nova webview, usamos a atual
  func webView(_ webView: WKWebView,
               createWebViewWith configuration: WKWebViewConfiguration,
               for navigationAction: WKNavigationAction,
               windowFeatures: WKWindowFeatures) -> WKWebView? {
    if navigationAction.targetFrame == nil {
      webView.load(navigationAction.request)
    }
    return nil
  }

  private func setBanner(_ text: String) {
    DispatchQueue.main.async { self.debugBanner.text = text }
  }

  deinit {
    webView?.configuration.userContentController.removeScriptMessageHandler(forName: "nativeHandler")
  }
}
