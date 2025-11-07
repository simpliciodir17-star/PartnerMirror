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
    l.text = "init…"
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    // JS de captura de token (igual ao seu, sem mudanças de lógica)
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

    let ucc = WKUserContentController()
    ucc.addUserScript(WKUserScript(source: injectedJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
    ucc.add(self, name: "nativeHandler")

    let cfg = WKWebViewConfiguration()
    cfg.websiteDataStore = .default()
    cfg.preferences.javaScriptEnabled = true
    cfg.userContentController = ucc

    let wv = WKWebView(frame: .zero, configuration: cfg)
    wv.navigationDelegate = self
    wv.uiDelegate = self
    wv.isOpaque = false           // evita “preto” com dark mode
    wv.backgroundColor = .white
    wv.scrollView.backgroundColor = .white
    wv.translatesAutoresizingMaskIntoConstraints = false
    self.webView = wv

    view.addSubview(banner)
    view.addSubview(webView)

    let g = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      banner.leadingAnchor.constraint(equalTo: g.leadingAnchor),
      banner.trailingAnchor.constraint(equalTo: g.trailingAnchor),
      banner.topAnchor.constraint(equalTo: g.topAnchor),
      banner.heightAnchor.constraint(equalToConstant: 38),

      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.topAnchor.constraint(equalTo: banner.bottomAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    // 1) mostra HTML local (se você ver isso, a view está OK)
    let html = """
    <html><head><meta name='viewport' content='width=device-width,initial-scale=1'>
    <style>body{background:#fff;font-family:-apple-system,Helvetica;display:flex;align-items:center;justify-content:center;height:100vh;margin:0}
    .box{border:2px solid #222;padding:24px;border-radius:12px}</style></head>
    <body><div class='box'>WKWebView OK — iniciando painel…</div></body></html>
    """
    webView.loadHTMLString(html, baseURL: nil)
    setBanner("boot local")

    // 2) em seguida, carrega o painel
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
      guard let self else { return }
      var req = URLRequest(url: self.partnerURL)
      req.cachePolicy = .reloadIgnoringLocalCacheData
      self.webView.load(req)
      self.setBanner("abrindo: \(self.partnerURL.host ?? "")")
    }
  }

  // bridge JS → nativo
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard message.name == "nativeHandler",
          let body = message.body as? [String: Any],
          (body["type"] as? String) == "auth_token",
          let token = body["token"] as? String,
          !token.isEmpty else { return }
    let snip = "\(token.prefix(4))…\(token.suffix(4))"
    if snip != lastTokenSnippet {
      lastTokenSnippet = snip
      setBanner("token: \(snip)")
    }
  }

  // navegação + erros visíveis
  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    setBanner("carregando…")
  }
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    setBanner("ok: \(webView.url?.host ?? "-")")
  }
  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    let e = error as NSError
    setBanner("erro: \(e.domain)#\(e.code)")
  }
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    let e = error as NSError
    setBanner("erro2: \(e.domain)#\(e.code)")
  }
  // abre target=_blank na mesma view
  func webView(_ webView: WKWebView,
               createWebViewWith configuration: WKWebViewConfiguration,
               for navigationAction: WKNavigationAction,
               windowFeatures: WKWindowFeatures) -> WKWebView? {
    if navigationAction.targetFrame == nil {
      webView.load(navigationAction.request)
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
