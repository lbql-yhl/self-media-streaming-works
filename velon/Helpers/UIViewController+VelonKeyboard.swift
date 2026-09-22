//
//  UIViewController+VelonKeyboard.swift
//  velon
//

import UIKit
import ObjectiveC

private var velonNavDelegateKey: UInt8 = 0

extension UIViewController {
    func velonEnableTapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(velonDismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func velonDismissKeyboard() {
        view.endEditing(true)
    }

    func velonShowAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = VelonTheme.primaryDeep
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func velonEmbedInNavigation() -> UINavigationController {
        let navigation = UINavigationController(rootViewController: self)
        VelonTheme.applyNavigationChrome(to: navigation.navigationBar)
        let delegate = VelonNavigationDelegate()
        objc_setAssociatedObject(navigation, &velonNavDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        navigation.delegate = delegate
        return navigation
    }
}
