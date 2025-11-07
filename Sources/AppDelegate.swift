diff --git a/Sources/AppDelegate.swift b/Sources/AppDelegate.swift
index ea43e0ae3c737755830738acd0f3d0bdcadc820d..a19bdc5a2bb1957249194d05323ca5d0b33c0e35 100644
--- a/Sources/AppDelegate.swift
+++ b/Sources/AppDelegate.swift
@@ -1,17 +1,30 @@
 import UIKit
 
 @main
 class AppDelegate: UIResponder, UIApplicationDelegate {
 
+  var window: UIWindow?
+
   func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
+    if #available(iOS 13.0, *) {
+      // A janela será criada pelo SceneDelegate nas versões que utilizam Scenes.
+    } else {
+      let window = UIWindow(frame: UIScreen.main.bounds)
+      window.rootViewController = WebViewController()
+      window.backgroundColor = .white
+      window.makeKeyAndVisible()
+      self.window = window
+    }
     return true
   }
 
   // iOS 13+ usa SceneDelegate
   func application(_ application: UIApplication,
                    configurationForConnecting connectingSceneSession: UISceneSession,
                    options: UIScene.ConnectionOptions) -> UISceneConfiguration {
-    UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
+    let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
+    configuration.delegateClass = SceneDelegate.self
+    return configuration
   }
 }
