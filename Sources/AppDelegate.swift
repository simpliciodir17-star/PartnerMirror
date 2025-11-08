import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? // Necessário para suporte a iOS < 13

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Suporte para iOS < 13 (não usa SceneDelegate)
        if #available(iOS 13.0, *) {
            // A janela é configurada no SceneDelegate.
        } else {
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.rootViewController = WebViewController()
            window.backgroundColor = .white
            window.makeKeyAndVisible()
            self.window = window
        }
        return true
    }

    // iOS 13+ usa SceneDelegate
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
