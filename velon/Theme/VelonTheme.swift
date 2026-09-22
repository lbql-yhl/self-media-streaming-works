//
//  VelonTheme.swift
//  velon
//

import UIKit

enum VelonTheme {
    static let primary = UIColor(red: 232 / 255, green: 123 / 255, blue: 123 / 255, alpha: 1)
    static let primaryDeep = UIColor(red: 196 / 255, green: 78 / 255, blue: 86 / 255, alpha: 1)
    static let coralGlow = UIColor(red: 255 / 255, green: 168 / 255, blue: 140 / 255, alpha: 1)
    static let saffron = UIColor(red: 242 / 255, green: 166 / 255, blue: 90 / 255, alpha: 1)
    static let basil = UIColor(red: 88 / 255, green: 158 / 255, blue: 120 / 255, alpha: 1)
    static let plum = UIColor(red: 148 / 255, green: 82 / 255, blue: 110 / 255, alpha: 1)
    static let charcoal = UIColor(red: 36 / 255, green: 32 / 255, blue: 31 / 255, alpha: 1)
    static let warmStone = UIColor(red: 126 / 255, green: 112 / 255, blue: 106 / 255, alpha: 1)
    static let creamSurface = UIColor(red: 255 / 255, green: 246 / 255, blue: 240 / 255, alpha: 1)
    static let mist = UIColor(red: 255 / 255, green: 236 / 255, blue: 228 / 255, alpha: 1)
    static let deepAccent = UIColor(red: 84 / 255, green: 48 / 255, blue: 42 / 255, alpha: 1)
    static let cardBackground = UIColor.white.withAlphaComponent(0.92)
    static let glass = UIColor.white.withAlphaComponent(0.55)
    static let separator = UIColor(red: 236 / 255, green: 214 / 255, blue: 204 / 255, alpha: 1)
    static let success = basil

    static func softShadow(for layer: CALayer, radius: CGFloat = 18, opacity: Float = 0.14, y: CGFloat = 10) {
        layer.shadowColor = deepAccent.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = CGSize(width: 0, height: y)
        layer.masksToBounds = false
    }

    static func glowShadow(for layer: CALayer) {
        layer.shadowColor = primary.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.masksToBounds = false
    }

    static func applyNavigationChrome(to navigationBar: UINavigationBar) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: charcoal,
            .font: UIFont.systemFont(ofSize: 17, weight: .heavy)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: charcoal,
            .font: UIFont.systemFont(ofSize: 32, weight: .black)
        ]
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = primaryDeep
        navigationBar.prefersLargeTitles = false
    }

    static func applyTabBarChrome(to tabBar: UITabBar) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        appearance.shadowColor = separator
        let item = UITabBarItemAppearance()
        let normal = item.normal
        normal.iconColor = warmStone
        normal.titleTextAttributes = [.foregroundColor: warmStone, .font: UIFont.systemFont(ofSize: 10, weight: .semibold)]
        let selected = item.selected
        selected.iconColor = primaryDeep
        selected.titleTextAttributes = [.foregroundColor: primaryDeep, .font: UIFont.systemFont(ofSize: 10, weight: .bold)]
        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = primaryDeep
        tabBar.unselectedItemTintColor = warmStone
        // Keep top hairline aligned; avoid clipping the indicator / separator.
        tabBar.layer.cornerRadius = 0
        tabBar.clipsToBounds = false
    }
}
