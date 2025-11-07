import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    return true
  }

  // iOS 13+ usa SceneDelegate
  func application(_ application: UIApplication,
                   configurationForConnecting connectingSceneSession: UISceneSession,
                   options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    let cfg = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    cfg.delegateClass = SceneDelegate.self
    return cfg
  }
}
