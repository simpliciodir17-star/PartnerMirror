import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    if #available(iOS 13.0, *) {
      // A janela será criada pelo SceneDelegate nas versões que utilizam Scenes.
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
    UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
}
