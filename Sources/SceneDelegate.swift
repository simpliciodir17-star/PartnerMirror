import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene,
             willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions) {
    guard let ws = (scene as? UIWindowScene) else { return }
    let win = UIWindow(windowScene: ws)
    win.rootViewController = WebViewController()
    win.backgroundColor = .systemBackground
    win.makeKeyAndVisible()
    self.window = win
  }
}
