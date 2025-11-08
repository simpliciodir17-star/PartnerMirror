import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    if #available(iOS 13.0, *) {
      // A janela será criada pelo SceneDelegate nas versões que utilizam Scenes.
    } else {
      // Fallback para iOS 12 e anteriores
      let window = UIWindow(frame: UIScreen.main.bounds)
      window.rootViewController = WebViewController()
      window.backgroundColor = .white
      window.makeKeyAndVisible()
      self.window = window
    }
    return true
  }

  // MARK: - UISceneSession Lifecycle (iOS 13+)

  func application(_ application: UIApplication,
                   configurationForConnecting connectingSceneSession: UISceneSession,
                   options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    
    let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    configuration.delegateClass = SceneDelegate.self
    return configuration
  }

  func application(_ application: UIApplication,
                   didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Chamado quando o usuário descarta uma cena.
  }
}
