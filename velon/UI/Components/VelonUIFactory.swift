//
//  VelonUIFactory.swift
//  velon
//

import UIKit

enum VelonUIFactory {
    static func heroTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 34, weight: .black)
        label.textColor = VelonTheme.charcoal
        label.numberOfLines = 0
        return label
    }

    static func titleLabel(_ text: String, size: CGFloat = 22) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: .heavy)
        label.textColor = VelonTheme.charcoal
        label.numberOfLines = 0
        return label
    }

    static func bodyLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = VelonTheme.warmStone
        label.numberOfLines = 0
        return label
    }

    static func primaryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .heavy)
        button.backgroundColor = VelonTheme.primary
        button.layer.cornerRadius = 18
        button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 18)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        VelonTheme.glowShadow(for: button.layer)
        return button
    }

    static func secondaryButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(VelonTheme.deepAccent, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        button.backgroundColor = VelonTheme.glass
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1.2
        button.layer.borderColor = VelonTheme.separator.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        return button
    }

    static func cardView() -> UIView {
        let view = UIView()
        view.backgroundColor = VelonTheme.cardBackground
        view.layer.cornerRadius = 22
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        VelonTheme.softShadow(for: view.layer)
        return view
    }

    static func glassPanel() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.62)
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.75).cgColor
        VelonTheme.softShadow(for: view.layer, radius: 20, opacity: 0.1, y: 8)
        return view
    }

    static func pillLabel(_ text: String, fill: UIColor = VelonTheme.primary, textColor: UIColor = .white) -> UILabel {
        let label = UILabel()
        label.text = "  \(text)  "
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textAlignment = .center
        label.textColor = textColor
        label.backgroundColor = fill
        label.layer.cornerRadius = 11
        label.clipsToBounds = true
        return label
    }
}

extension UIViewController {
    func velonInstallAmbient(_ mood: VelonAmbientCanvas.Mood) -> VelonAmbientCanvas {
        let canvas = VelonAmbientCanvas()
        canvas.mood = mood
        canvas.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(canvas, at: 0)
        NSLayoutConstraint.activate([
            canvas.topAnchor.constraint(equalTo: view.topAnchor),
            canvas.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvas.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvas.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        return canvas
    }
}
