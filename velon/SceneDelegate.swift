//
//  SceneDelegate.swift
//  velon
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = VelonMainTabBarController()
        window.tintColor = VelonTheme.primaryDeep
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        VelonTrackingConsent.requestIfNeededWhenActive()
    }
}
