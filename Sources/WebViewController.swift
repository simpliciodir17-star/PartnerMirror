diff --git a/Sources/WebViewController.swift b/Sources/WebViewController.swift
index da3fc1cbfa94afb41466e86f46b4a79c06ef476b..e99bb2fc9a9876e56b43a511c6ea623eb4d5df52 100644
--- a/Sources/WebViewController.swift
+++ b/Sources/WebViewController.swift
@@ -1,31 +1,31 @@
 import UIKit
 import WebKit
 
 final class WebViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
   private var webView: WKWebView!
-  // Endereço correto do painel (raiz, sem /partner)
+  // URL pública correta do painel do parceiro
   private let partnerURL = URL(string: "https://partner.obynexbroker.com/")!
   private var lastTokenSnippet: String?
 
   override func viewDidLoad() {
     super.viewDidLoad()
     view.backgroundColor = .systemBackground
 
     // JS para capturar token (local/session storage ou cookie)
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
