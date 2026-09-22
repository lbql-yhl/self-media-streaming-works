//
//  VelonLegalTextViewController.swift
//  velon
//

import UIKit

final class VelonLegalTextViewController: UIViewController {
    private let titleText: String
    private let body: String

    init(titleText: String, body: String) {
        self.titleText = titleText
        self.body = body
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = titleText
        _ = velonInstallAmbient(.profile)

        let card = VelonUIFactory.glassPanel()
        card.translatesAutoresizingMaskIntoConstraints = false
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.textColor = VelonTheme.charcoal
        textView.font = .systemFont(ofSize: 16, weight: .medium)
        textView.text = body
        textView.textContainerInset = .zero
        card.addSubview(textView)
        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            textView.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            textView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])
        VelonMotion.staggerIn(views: [card], fromY: 20)
    }
}
