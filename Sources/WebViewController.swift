import UIKit
import WebKit

final class WebViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    private let partnerURL = URL(string: "https://partner.obynexbroker.com/")!
    private var lastTokenSnippet: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let userContentController = WKUserContentController()
        userContentController.add(self, name: "nativeHandler")

        // Script JavaScript para buscar o token e enviá-lo para o código Swift
        let scriptSource = """
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
              
              if (token && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.nativeHandler) {
                window.webkit.messageHandlers.nativeHandler.postMessage({type:'auth_token', token: token});
              }
            } catch (e) {
              console.error("Token search error:", e);
            }
          }
          
          // Execute logo e a cada 5 segundos
          findToken();
          setInterval(findToken, 5000);
        })();
        """
        
        let userScript = WKUserScript(source: scriptSource, 
                                      injectionTime: .atDocumentEnd, 
                                      forMainFrameOnly: true)
        userContentController.addUserScript(userScript)

        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .default()
        cfg.preferences.javaScriptEnabled = true
        cfg.userContentController = userContentController

        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.navigationDelegate = self
        wv.uiDelegate = self
        wv.isOpaque = false
        wv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wv)
        
        NSLayoutConstraint.activate([
            wv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wv.topAnchor.constraint(equalTo: view.topAnchor),
            wv.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.webView = wv

        // Prevenção da tela preta: Carrega HTML temporário antes da navegação
        let antiBlackScreenHTML = "<html><body style='font:16px -apple-system;background:#fff;display:flex;align-items:center;justify-content:center;height:100vh'>Carregando parceiro...</body></html>"
        webView.loadHTMLString(antiBlackScreenHTML, baseURL: nil)

        // Navega para a URL de destino
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            var req = URLRequest(url: self.partnerURL)
            req.cachePolicy = .reloadIgnoringLocalCacheData
            self.webView.load(req)
        }
    }

    // MARK: - WKScriptMessageHandler (Captura do Token)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "nativeHandler",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String, type == "auth_token",
              let token = body["token"] as? String, 
              !token.isEmpty else {
            return
        }

        let snippet = tokenSnippet(from: token)
        guard lastTokenSnippet != snippet else { return }
        lastTokenSnippet = snippet

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: "Token capturado",
                                          message: "Token (aff_sid) capturado: \(snippet)",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            if self.presentedViewController == nil {
                self.present(alert, animated: true, completion: nil)
            } else {
                self.dismiss(animated: false) {
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    // MARK: - WKUIDelegate (Abre links em novas janelas na mesma webview)
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    // MARK: - Auxiliar
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
