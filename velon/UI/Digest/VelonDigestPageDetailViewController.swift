//
//  VelonDigestPageDetailViewController.swift
//  velon
//

import UIKit

final class VelonDigestPageDetailViewController: UIViewController {
    private let draft: VelonRouteDraft
    private let pageIndex: Int
    private let pageImage: UIImage
    private let note: VelonVisitNote?
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let shareButton = VelonUIFactory.primaryButton(title: "Share This Card")

    init(draft: VelonRouteDraft, pageIndex: Int, pageImage: UIImage, note: VelonVisitNote?) {
        self.draft = draft
        self.pageIndex = pageIndex
        self.pageImage = pageImage
        self.note = note
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = pageIndex == 0 ? "Cover Detail" : "Note Detail"
        _ = velonInstallAmbient(.digest)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        let imageView = UIImageView(image: pageImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 22
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1440.0 / 1080.0).isActive = true
        VelonTheme.softShadow(for: imageView.layer, radius: 16, opacity: 0.14, y: 8)

        let typePill = VelonUIFactory.pillLabel(
            pageIndex == 0 ? "COVER" : "TASTE NOTE",
            fill: pageIndex == 0 ? VelonTheme.plum : VelonTheme.primary
        )

        let infoCard = VelonUIFactory.cardView()
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = 8
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(infoStack)

        let city = VelonCityLookup.city(id: draft.cityId)
        if pageIndex == 0 {
            infoStack.addArrangedSubview(VelonUIFactory.titleLabel(city?.name ?? "City", size: 22))
            infoStack.addArrangedSubview(VelonUIFactory.bodyLabel(draft.title))
            infoStack.addArrangedSubview(VelonUIFactory.bodyLabel(city?.summary ?? "Food trip cover card for your digest album."))
            infoStack.addArrangedSubview(VelonUIFactory.bodyLabel("\(draft.spotCount) stops on this route"))
        } else if let note {
            let spot = VelonPlaceLookup.spot(id: note.spotId)
            infoStack.addArrangedSubview(VelonUIFactory.titleLabel(spot?.name ?? "Stop", size: 22))
            infoStack.addArrangedSubview(VelonUIFactory.bodyLabel("\(city?.name ?? draft.cityId) · \(spot?.district ?? "Local")"))
            let noteTitle = VelonUIFactory.titleLabel("Taste note", size: 16)
            infoStack.addArrangedSubview(noteTitle)
            let body = VelonUIFactory.bodyLabel(note.tasteNote)
            body.textColor = VelonTheme.charcoal
            infoStack.addArrangedSubview(body)
            if note.photoRelativePath != nil {
                infoStack.addArrangedSubview(VelonUIFactory.pillLabel("PHOTO ATTACHED", fill: VelonTheme.basil))
            }
        }

        NSLayoutConstraint.activate([
            infoStack.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 16),
            infoStack.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            infoStack.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),
            infoStack.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -16)
        ])

        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)

        [typePill, imageView, infoCard, shareButton].forEach { stack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -28),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])

        VelonMotion.staggerIn(views: stack.arrangedSubviews, fromY: 20, baseDelay: 0.04)
    }

    @objc private func shareTapped() {
        VelonMotion.pop(shareButton)
        let activity = UIActivityViewController(activityItems: [pageImage], applicationActivities: nil)
        if let pop = activity.popoverPresentationController {
            pop.sourceView = shareButton
            pop.sourceRect = shareButton.bounds
        }
        present(activity, animated: true)
    }
}
