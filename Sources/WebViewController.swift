import UIKit
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
  private var webView: WKWebView!
  private let partnerURL = URL(string: "https://partner.obynexbroker.com/")!
  private var lastTokenSnippet: String?

  private let banner: UILabel = {
    let l = UILabel()
    l.backgroundColor = UIColor(white: 0.95, alpha: 1)
    l.textColor = .black
    l.textAlignment = .center
    l.font = .systemFont(ofSize: 13, weight: .semibold)
    l.numberOfLines = 2
    l.text = "diagnóstico: iniciando…"
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
  }()

  private let bgTestView: UIView = {
    let v = UIView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.backgroundColor = .white // deixa CLARO no preview
    return v
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    // Controller + JS (mantém captura de token)
    let ucc = WKUserContentController()
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
        } catch(e) {}
      }
      window.addEventListener('load', findToken);
      setInterval(findToken, 3000);
    })();
    """#
    ucc.addUserScript(WKUserScript(source: injectedJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
    ucc.add(self, name: "nativeHandler")

    let cfg = WKWebViewConfiguration()
    cfg.websiteDataStore = .default()
    cfg.preferences.javaScriptEnabled = true
    cfg.userContentController = ucc

    let wv = WKWebView(frame: .zero, configuration: cfg)
    wv.navigationDelegate = self
    wv.uiDelegate = self
    // 🔧 Render “preto” às vezes é opacidade: força transparente + fundo branco
    wv.isOpaque = false
    wv.backgroundColor = .clear
    wv.scrollView.backgroundColor = .clear
    // 🔧 Alguns painéis exigem UA Safari
    wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
    wv.translatesAutoresizingMaskIntoConstraints = false
    webView = wv

    // Hierarquia
    view.addSubview(bgTestView)   // camada de fundo branca
    view.addSubview(banner)       // banner topo
    view.addSubview(webView)      // webview por cima

    let g = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      bgTestView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      bgTestView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      bgTestView.topAnchor.constraint(equalTo: view.topAnchor),
      bgTestView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      banner.leadingAnchor.constraint(equalTo: g.leadingAnchor),
      banner.trailingAnchor.constraint(equalTo: g.trailingAnchor),
      banner.topAnchor.constraint(equalTo: g.topAnchor),
      banner.heightAnchor.constraint(equalToConstant: 38),

      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.topAnchor.constraint(equalTo: banner.bottomAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    // 🔎 Etapa 1: carrega HTML inline (sem internet). Se isso aparecer, WKWebView renderiza.
    let html = """
    <html><head><meta name='viewport' content='width=device-width,initial-scale=1'>
    <style>body{background:#fff;font-family:-apple-system,Helvetica;display:flex;align-items:center;justify-content:center;height:100vh;margin:0}
    .box{border:2px solid #222;padding:24px;border-radius:12px}</style></head>
    <body><div class='box'>WKWebView OK (HTML inline)</div></body></html>
    """
    webView.loadHTMLString(html, baseURL: nil)
    setBanner("diagnóstico: HTML inline")

    // 🔎 Etapa 2: após 2s, tenta abrir o domínio real; se travar, pelo menos vimos a Etapa 1
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
      guard let self else { return }
      self.setBanner("navegando: \(self.partnerURL.absoluteString.prefix(60))")
      var req = URLRequest(url: self.partnerURL)
      req.cachePolicy = .reloadIgnoringLocalCacheData
      self.webView.load(req)
    }
  }

  // Bridge JS → nativo (token)
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard message.name == "nativeHandler",
          let body = message.body as? [String: Any],
          let type = body["type"] as? String else { return }
    if type == "auth_token", let token = body["token"] as? String, !token.isEmpty {
      let snippet = "\(token.prefix(4))…\(token.suffix(4))"
      if snippet != lastTokenSnippet {
        lastTokenSnippet = snippet
        let a = UIAlertController(title: "Token capturado", message: snippet, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
      }
    }
  }

  // Navegação: mostra erros no banner
  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    setBanner("carregando…")
  }
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    setBanner("ok: \(webView.url?.host ?? "")")
  }
  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    let e = error as NSError
    setBanner("erro: \(e.domain)#\(e.code)")
  }
  func webView(_ webView: WKWebView,
               createWebViewWith configuration: WKWebViewConfiguration,
               for navigationAction: WKNavigationAction,
               windowFeatures: WKWindowFeatures) -> WKWebView? {
    if navigationAction.targetFrame == nil {
      webView.load(navigationAction.request) // abre target=_blank na mesma view
    }
    return nil
  }

  private func setBanner(_ t: String) {
    DispatchQueue.main.async { self.banner.text = t }
  }

  deinit {
    webView?.configuration.userContentController.removeScriptMessageHandler(forName: "nativeHandler")
  }
}
