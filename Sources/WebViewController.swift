import UIKit
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    private var webView: WKWebView!
    private let partnerURL = URL(string: "https://partner.obynexbroker.com/")!
    private var lastTokenSnippet: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.preferences.javaScriptEnabled = true

        let wv = WKWebView(frame: .zero, configuration: config)
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
        self.webView = wv

        let antiBlackScreenHTML = """
        <html><body style='font:16px -apple-system;
                           display:flex;
                           align-items:center;
                           justify-content:center;
                           height:100vh;
                           background:#ffffff'>
        Carregando parceiro...
        </body></html>
        """
        wv.loadHTMLString(antiBlackScreenHTML, baseURL: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            var req = URLRequest(url: self.partnerURL)
            req.cachePolicy = .reloadIgnoringLocalCacheData
            self.webView.load(req)
        }
    }

    // MARK: - Navegação

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        captureAffiliateTokenFromCookies()
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let url = navigationAction.request.url {
            captureAffiliateTokenFromURL(url)
        }
        decisionHandler(.allow)
    }

    // MARK: - Captura de token (cookies + query)

    private func captureAffiliateTokenFromCookies() {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }

            let targetNames: [String] = [
                "aff_sid",
                "aff_session",
                "affiliate_sid",
                "affiliate_token"
            ]

            if let cookie = cookies.first(where: { targetNames.contains($0.name) && !$0.value.isEmpty }) {
                self.handleCapturedToken(cookie.value, source: "cookie:\(cookie.name)")
            }
        }
    }

    private func captureAffiliateTokenFromURL(_ url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = comps.queryItems else { return }

        let targetParams = ["aff_sid", "aff_session", "affiliate_sid", "affiliate_token"]

        for name in targetParams {
            if let value = items.first(where: { $0.name == name })?.value,
               !value.isEmpty {
                handleCapturedToken(value, source: "query:\(name)")
                break
            }
        }
    }

    private func handleCapturedToken(_ token: String, source: String) {
        guard !token.isEmpty else { return }
        let snippet = tokenSnippet(from: token)
        guard snippet != lastTokenSnippet else { return }
        lastTokenSnippet = snippet

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: "Token capturado",
                                          message: "\(snippet)\n(\(source))",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            if self.presentedViewController == nil {
                self.present(alert, animated: true)
            } else {
                self.dismiss(animated: false) {
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - target=_blank

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    private func tokenSnippet(from token: String) -> String {
        guard token.count > 8 else { return token }
        return "\(token.prefix(4))…\(token.suffix(4))"
    }
}
