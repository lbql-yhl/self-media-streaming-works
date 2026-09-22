//
//  VelonCustomPlaceDetailViewController.swift
//  velon
//

import UIKit

final class VelonCustomPlaceDetailViewController: UIViewController {
    private let spotId: String
    private let store = VelonUserStore.shared
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let wishlistButton = VelonUIFactory.secondaryButton(title: "Save to Wishlist")
    private let addToRouteButton = VelonUIFactory.primaryButton(title: "Add to a Route Draft")
    private let deleteButton = VelonUIFactory.secondaryButton(title: "Delete Custom Place")

    init(spotId: String) {
        self.spotId = spotId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        _ = velonInstallAmbient(.detail)
        setupLayout()
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .velonUserDataDidChange, object: nil)
        reload()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func reload() {
        guard let spot = store.customPlace(id: spotId) else {
            navigationController?.popViewController(animated: true)
            return
        }
        title = spot.name
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buildContent(spot: spot)
        refreshWishlistTitle()
        VelonMotion.staggerIn(views: contentStack.arrangedSubviews, fromY: 20, baseDelay: 0.04)
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -28),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 17, weight: .heavy)]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func buildContent(spot: VelonSpot) {
        let hero = UIImageView()
        hero.translatesAutoresizingMaskIntoConstraints = false
        hero.heightAnchor.constraint(equalToConstant: 220).isActive = true
        VelonImageLoader.apply(to: hero, named: spot.imageName, cornerRadius: 28)

        let card = VelonUIFactory.glassPanel()
        card.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        let customPill = VelonUIFactory.pillLabel("CUSTOM PLACE", fill: VelonTheme.saffron)
        let name = VelonUIFactory.heroTitle(spot.name)
        name.font = .systemFont(ofSize: 28, weight: .black)
        name.textColor = .white
        let meta = VelonUIFactory.bodyLabel("\(spot.district) · \(VelonFoodCatalog.city(id: spot.cityId)?.name ?? spot.cityId)")
        meta.textColor = UIColor.white.withAlphaComponent(0.88)
        let blurb = VelonUIFactory.bodyLabel(spot.blurb)
        blurb.textColor = UIColor.white.withAlphaComponent(0.95)
        let tags = VelonUIFactory.bodyLabel("Tastes: " + spot.tags.map(\.displayName).joined(separator: ", "))
        tags.textColor = UIColor.white.withAlphaComponent(0.9)
        let inner = UIStackView(arrangedSubviews: [customPill, name, meta, blurb, tags])
        inner.axis = .vertical
        inner.spacing = 8
        inner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(inner)
        card.translatesAutoresizingMaskIntoConstraints = false

        let pitfall = VelonUIFactory.cardView()
        pitfall.translatesAutoresizingMaskIntoConstraints = false
        let pitfallTitle = VelonUIFactory.titleLabel("Pitfall Notes", size: 18)
        let queue = VelonUIFactory.bodyLabel("Queue: \(spot.pitfall.queueNote)")
        queue.textColor = VelonTheme.charcoal
        let rest = VelonUIFactory.bodyLabel("Rest days: \(spot.pitfall.restDays)")
        rest.textColor = VelonTheme.charcoal
        let window = VelonUIFactory.bodyLabel("Best window: \(spot.pitfall.bestWindow)")
        window.textColor = VelonTheme.charcoal
        let pitfallStack = UIStackView(arrangedSubviews: [pitfallTitle, queue, rest, window])
        pitfallStack.axis = .vertical
        pitfallStack.spacing = 8
        pitfallStack.translatesAutoresizingMaskIntoConstraints = false
        pitfall.addSubview(pitfallStack)

        wishlistButton.addTarget(self, action: #selector(toggleWishlist), for: .touchUpInside)
        addToRouteButton.addTarget(self, action: #selector(addToRoute), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deletePlace), for: .touchUpInside)
        deleteButton.setTitleColor(VelonTheme.primaryDeep, for: .normal)

        [hero, card, pitfall, wishlistButton, addToRouteButton, deleteButton].forEach { contentStack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            pitfallStack.topAnchor.constraint(equalTo: pitfall.topAnchor, constant: 16),
            pitfallStack.leadingAnchor.constraint(equalTo: pitfall.leadingAnchor, constant: 16),
            pitfallStack.trailingAnchor.constraint(equalTo: pitfall.trailingAnchor, constant: -16),
            pitfallStack.bottomAnchor.constraint(equalTo: pitfall.bottomAnchor, constant: -16)
        ])
    }

    private func refreshWishlistTitle() {
        let title = store.isWishlisted(spotId) ? "Remove from Wishlist" : "Save to Wishlist"
        wishlistButton.setTitle(title, for: .normal)
    }

    @objc private func toggleWishlist() {
        store.toggleWishlist(spotId)
        refreshWishlistTitle()
        VelonMotion.pop(wishlistButton)
    }

    @objc private func addToRoute() {
        guard let spot = store.customPlace(id: spotId) else { return }
        VelonMotion.pop(addToRouteButton)
        let drafts = store.drafts(forCity: spot.cityId).filter { $0.status != .archived }
        if drafts.isEmpty {
            let draft = store.createDraft(
                cityId: spot.cityId,
                title: "\(VelonFoodCatalog.city(id: spot.cityId)?.name ?? "City") Draft",
                spotIds: [spot.id]
            )
            let editor = VelonRouteEditorViewController(draftId: draft.id)
            editor.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(editor, animated: true)
            return
        }
        let sheet = UIAlertController(title: "Add to Draft", message: nil, preferredStyle: .actionSheet)
        sheet.view.tintColor = VelonTheme.primaryDeep
        for draft in drafts {
            sheet.addAction(UIAlertAction(title: draft.title, style: .default, handler: { [weak self] _ in
                guard let self else { return }
                var updated = draft
                if !updated.stops.contains(where: { $0.spotId == spot.id }) {
                    let day = updated.stops.map(\.dayIndex).max() ?? 0
                    updated.stops.append(VelonRouteStop(spotId: spot.id, dayIndex: day))
                    updated.updatedAt = Date()
                    self.store.saveDraft(updated)
                }
                let editor = VelonRouteEditorViewController(draftId: updated.id)
                editor.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(editor, animated: true)
            }))
        }
        sheet.addAction(UIAlertAction(title: "Create New Draft", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            let draft = self.store.createDraft(
                cityId: spot.cityId,
                title: "\(VelonFoodCatalog.city(id: spot.cityId)?.name ?? "City") Draft",
                spotIds: [spot.id]
            )
            let editor = VelonRouteEditorViewController(draftId: draft.id)
            editor.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(editor, animated: true)
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    @objc private func deletePlace() {
        let alert = UIAlertController(title: "Delete Place?", message: "This removes it from wishlist and route drafts.", preferredStyle: .alert)
        alert.view.tintColor = VelonTheme.primaryDeep
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            guard let self else { return }
            self.store.deleteCustomPlace(id: self.spotId)
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
