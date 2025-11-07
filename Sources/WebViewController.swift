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

        // JavaScript para buscar o token no storage/cookie e enviar para o app
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
                } catch(e) { /* silencioso */ }
            }
            window.addEventListener('load', findToken);
            setInterval(findToken, 3000);
        })();
        """

        // Configura o controlador de conteúdo para injetar o JS e receber mensagens
        let userContent = WKUserContentController()
        userContent.addUserScript(WKUserScript(source: tokenJS,
                                               injectionTime: .atDocumentEnd,
                                               forMainFrameOnly: true))
        userContent.add(self, name: "nativeHandler")

        // Configuração da WebView: persistência de cookies/localStorage e JS habilitado
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()          // Armazena cookies/localStorage de forma persistente
        config.preferences.javaScriptEnabled = true
        config.userContentController = userContent

        // Cria a WebView
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        wv.uiDelegate = self
        wv.isOpaque = false
        wv.backgroundColor = .systemBackground
        wv.scrollView.backgroundColor = .systemBackground
        wv.translatesAutoresizingMaskIntoConstraints = false
        self.webView = wv

        // Adiciona ao layout
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Carrega o painel
        var request = URLRequest(url: partnerURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        webView.load(request)
    }

    // Recebe mensagens do JavaScript
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "nativeHandler",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String,
              type == "auth_token",
              let token = body["token"] as? String,
              !token.isEmpty else { return }

        // Exibe apenas início e fim do token para debug (não divulga o valor completo)
        let snippet = "\(token.prefix(4))…\(token.suffix(4))"
        if snippet != lastTokenSnippet {
            lastTokenSnippet = snippet
            let alert = UIAlertController(title: "Token capturado", message: snippet, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    // Corrige links com target="_blank": abre na mesma WebView
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
