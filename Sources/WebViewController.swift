// ... Cole este código dentro da classe WebViewController ...

  private var lastTokenSnippet: String?

  // Esta função é o novo método de captura de token
  func webView(_ webView: WKWebView,
               decidePolicyFor navigationResponse: WKNavigationResponse,
               decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

      // 1. Tentar obter a resposta HTTP
      guard let httpResponse = navigationResponse.response as? HTTPURLResponse,
            let headers = httpResponse.allHeaderFields as? [String: String] else {
          decisionHandler(.allow)
          return
      }

      // 2. Procurar pelo cabeçalho 'Set-Cookie'
      let setCookieHeader = headers["Set-Cookie"] ?? headers["set-cookie"]

      if let cookieString = setCookieHeader {
          let cookies = cookieString.components(separatedBy: ";")
          
          for cookie in cookies {
              let trimmedCookie = cookie.trimmingCharacters(in: .whitespacesAndNewlines)
              
              // 3. Procurar pelo nosso cookie 'aff_sid'
              if trimmedCookie.hasPrefix("aff_sid=") {
                  let token = String(trimmedCookie.dropFirst("aff_sid=".count))
                  
                  if !token.isEmpty {
                      let snippet = tokenSnippet(from: token)
                      
                      // 4. Evitar mostrar o mesmo token repetidamente
                      guard snippet != lastTokenSnippet else {
                          continue
                      }
                      lastTokenSnippet = snippet

                      // 5. Mostrar o alerta (na thread principal)
                      DispatchQueue.main.async { [weak self] in
                          self?.showAlert(with: snippet)
                      }
                      break
                  }
              }
          }
      }

      // 6. Permitir que a navegação continue
      decisionHandler(.allow)
  }
  
  // MARK: - Funções Auxiliares (Helpers)

  private func showAlert(with snippet: String) {
      let alert = UIAlertController(title: "Token (aff_sid) Capturado",
                                    message: "Token: \(snippet)",
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
