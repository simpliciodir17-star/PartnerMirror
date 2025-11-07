import UIKit
import WebKit

final class WebViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    // URL correta para carregar o painel de afiliados
    private let partnerURL = URL(string: "https://partner.obynexbroker.com/")!
    private var lastTokenSnippet: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Script para procurar o token de sessão nos storages e cookies
        let js = """
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
                        window.webkit.messageHandlers.nativeHandler.postMessage({ type: 'auth_token', token: token });
                    }
                } catch (e) { /* ignorar */ }
            }
            window.addEventListener('load', findToken);
            setInterval(findToken, 3000);
        })();
        """

        let userContent = WKUserContentController()
        userContent.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        userContent.add(self, name: "nativeHandler")

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.preferences.javaScriptEnabled = true
        config.userContentController = userContent

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground
        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        var request = URLRequest(url: partnerURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        webView.load(request)
    }

    // Trata mensagens do JavaScript (token de sessão)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "nativeHandler",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String,
              type == "auth_token",
              let token = body["token"] as? String,
              !token.isEmpty else { return }

        let snippet = "\(token.prefix(4))…\(token.suffix(4))"
        if snippet != lastTokenSnippet {
            lastTokenSnippet = snippet
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Token capturado", message: snippet, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }

    // Garante que links com target=_blank abram na mesma WebView
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
