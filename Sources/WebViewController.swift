import UIKit
import WebKit

// Garantimos que ele conforma com WKNavigationDelegate e WKUIDelegate
final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
  private var webView: WKWebView!
  private let partnerURL = URL(string: "https://partner.obynexbroker.com/")!
  // Propriedade para guardar o último token
  private var lastTokenSnippet: String?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    let cfg = WKWebViewConfiguration()
    cfg.websiteDataStore = .default()
    cfg.preferences.javaScriptEnabled = true

    let wv = WKWebView(frame: .zero, configuration: cfg)
    wv.navigationDelegate = self // Essencial para a captura nativa
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

    // 1) Prova de vida (Correção da tela preta)
    webView.loadHTMLString("<html><body style='font:16px -apple-system;background:#fff;display:flex;align-items:center;justify-content:center;height:100vh'>WKWebView OK…</body></html>", baseURL: nil)

    // 2) Navega para o painel
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      guard let self else { return }
      var req = URLRequest(url: self.partnerURL)
      req.cachePolicy = .reloadIgnoringLocalCacheData
      self.webView.load(req)
    }
  }

  // Abre target=_blank na mesma webview
  func webView(_ webView: WKWebView,
               createWebViewWith configuration: WKWebViewConfiguration,
               for navigationAction: WKNavigationAction,
               windowFeatures: WKWindowFeatures) -> WKWebView? {
    if navigationAction.targetFrame == nil {
      webView.load(navigationAction.request)
    }
    return nil
  }

  // --- LÓGICA DE CAPTURA DE TOKEN (HttpOnly) ---

  func webView(_ webView: WKWebView,
               decidePolicyFor navigationResponse: WKNavigationResponse,
               decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

      guard let httpResponse = navigationResponse.response as? HTTPURLResponse,
            let headers = httpResponse.allHeaderFields as? [String: String] else {
          decisionHandler(.allow)
          return
      }

      let setCookieHeader = headers["Set-Cookie"] ?? headers["set-cookie"]

      if let cookieString = setCookieHeader {
          let cookies = cookieString.components(separatedBy: ";")
          
          for cookie in cookies {
              let trimmedCookie = cookie.trimmingCharacters(in: .whitespacesAndNewlines)
              
              if trimmedCookie.hasPrefix("aff_sid=") {
                  let token = String(trimmedCookie.dropFirst("aff_sid=".count))
                  
                  if !token.isEmpty {
                      let snippet = tokenSnippet(from: token)
                      guard snippet != lastTokenSnippet else {
                          continue
                      }
                      lastTokenSnippet = snippet

                      // Chama a função auxiliar, na thread principal
                      DispatchQueue.main.async { [weak self] in
                          self?.showAlert(with: snippet)
                      }
                      break
                  }
              }
          }
      }
      decisionHandler(.allow)
  }
  
  // MARK: - Funções Auxiliares (Helpers)

  private func showAlert(with snippet: String) {
      let alert = UIAlertController(title: "Token (aff_sid) Capturado",
                                    message: "Token: \(snippet)",
                                    preferredStyle: .alert)
      
      // FIX: Substituímos 'nil' por closures vazios para corrigir o erro de tipo
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in }))
      
      if self.presentedViewController == nil {
          self.present(alert, animated: true, completion: { })
      } else {
          self.dismiss(animated: false) {
              self.present(alert, animated: true, completion: { })
          }
      }
  }

  private func tokenSnippet(from token: String) -> String {
      if token.count <= 8 {
          return token
      }
      let startIndex = token.startIndex
      let endIndex = token.index(token.endIndex, offsetBy: -4)
      let prefix = token[startIndex..<token.index(startIndex, offsetBy: 4)]
      let suffix = token[endIndex..<token.endIndex]
      return "\(prefix)…\(suffix)"
  }
}
