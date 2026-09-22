//
//  VelonMainTabBarController.swift
//  velon
//

import UIKit

final class VelonMainTabBarController: UITabBarController {
    private let glowBar = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        VelonTheme.applyTabBarChrome(to: tabBar)
        view.backgroundColor = VelonTheme.creamSurface

        let discover = VelonDiscoverViewController().velonEmbedInNavigation()
        discover.tabBarItem = UITabBarItem(title: "Discover", image: UIImage(systemName: "fork.knife.circle.fill"), tag: 0)

        let routes = VelonRoutesViewController().velonEmbedInNavigation()
        routes.tabBarItem = UITabBarItem(title: "Routes", image: UIImage(systemName: "map.fill"), tag: 1)

        let digest = VelonDigestViewController().velonEmbedInNavigation()
        digest.tabBarItem = UITabBarItem(title: "Digest", image: UIImage(systemName: "book.fill"), tag: 2)

        let profile = VelonProfileViewController().velonEmbedInNavigation()
        profile.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.crop.circle.fill"), tag: 3)

        viewControllers = [discover, routes, digest, profile]
        delegate = self

        glowBar.backgroundColor = VelonTheme.primary
        glowBar.layer.cornerRadius = 2
        glowBar.isUserInteractionEnabled = false
        // Frame-based layout under each tab button.
        glowBar.translatesAutoresizingMaskIntoConstraints = true
        tabBar.addSubview(glowBar)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tabBar.bringSubviewToFront(glowBar)
        moveGlow(animated: false)
    }

    private func tabButtons() -> [UIView] {
        tabBar.subviews
            .filter { String(describing: type(of: $0)).contains("TabBarButton") }
            .sorted { $0.frame.minX < $1.frame.minX }
    }

    private func moveGlow(animated: Bool) {
        let buttons = tabButtons()
        guard selectedIndex >= 0, selectedIndex < buttons.count else {
            glowBar.isHidden = true
            return
        }
        glowBar.isHidden = false
        let button = buttons[selectedIndex]
        let barWidth: CGFloat = 28
        let barHeight: CGFloat = 3
        let target = CGRect(
            x: button.frame.midX - barWidth / 2,
            y: 6,
            width: barWidth,
            height: barHeight
        )
        if animated {
            UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.5, options: [.beginFromCurrentState]) {
                self.glowBar.frame = target
            }
        } else {
            glowBar.frame = target
        }
    }
}

extension VelonMainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        moveGlow(animated: true)
        VelonMotion.pop(tabBar)
        if let nav = viewController as? UINavigationController {
            VelonMotion.staggerIn(views: nav.topViewController?.view.subviews.prefix(4).map { $0 } ?? [], fromY: 12, baseDelay: 0.03)
        }
    }
}
