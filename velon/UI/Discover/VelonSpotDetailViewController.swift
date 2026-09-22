//
//  VelonSpotDetailViewController.swift
//  velon
//

import UIKit

final class VelonSpotDetailViewController: UIViewController {
    private let spot: VelonSpot
    private let store = VelonUserStore.shared
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let wishlistButton = VelonUIFactory.secondaryButton(title: "Add to Wishlist")
    private let addToRouteButton = VelonUIFactory.primaryButton(title: "Add to a Route Draft")
    private let hero = UIImageView()

    init(spot: VelonSpot) {
        self.spot = spot
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = spot.name
        _ = velonInstallAmbient(.detail)
        setupLayout()
        refreshWishlistChrome()
        VelonMotion.staggerIn(views: contentStack.arrangedSubviews, fromY: 26, baseDelay: 0.04)
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "heart"),
            style: .plain,
            target: self,
            action: #selector(toggleWishlist)
        )
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Wishlist"

        hero.translatesAutoresizingMaskIntoConstraints = false
        hero.heightAnchor.constraint(equalToConstant: 240).isActive = true
        VelonImageLoader.apply(to: hero, named: spot.imageName, cornerRadius: 28)
        hero.transform = CGAffineTransform(rotationAngle: -0.02)

        let overlapCard = VelonUIFactory.glassPanel()
        overlapCard.translatesAutoresizingMaskIntoConstraints = false
        let name = VelonUIFactory.heroTitle(spot.name)
        name.font = .systemFont(ofSize: 28, weight: .black)
        name.textColor = VelonTheme.charcoal
        let district = VelonUIFactory.bodyLabel("\(spot.district) · \(VelonFoodCatalog.city(id: spot.cityId)?.name ?? "")")
        district.textColor = VelonTheme.warmStone
        let blurb = VelonUIFactory.bodyLabel(spot.blurb)
        blurb.textColor = VelonTheme.charcoal
        let tagRow = UIStackView()
        tagRow.axis = .horizontal
        tagRow.spacing = 8
        tagRow.alignment = .leading
        for tag in spot.tags {
            tagRow.addArrangedSubview(VelonUIFactory.pillLabel(tag.displayName, fill: VelonTheme.primary))
        }
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tagRow.addArrangedSubview(spacer)

        let inner = UIStackView(arrangedSubviews: [name, district, blurb, tagRow])
        inner.axis = .vertical
        inner.spacing = 8
        inner.translatesAutoresizingMaskIntoConstraints = false
        overlapCard.addSubview(inner)

        let pitfallCard = VelonUIFactory.cardView()
        pitfallCard.translatesAutoresizingMaskIntoConstraints = false
        let pitfallTitle = VelonUIFactory.titleLabel("Pitfall Notes", size: 18)
        let queue = makeNoteRow(icon: "person.3.fill", title: "Queue", body: spot.pitfall.queueNote, tint: VelonTheme.primary)
        let rest = makeNoteRow(icon: "moon.zzz.fill", title: "Rest days", body: spot.pitfall.restDays, tint: VelonTheme.plum)
        let window = makeNoteRow(icon: "clock.fill", title: "Best window", body: spot.pitfall.bestWindow, tint: VelonTheme.saffron)
        let pitfallStack = UIStackView(arrangedSubviews: [pitfallTitle, queue, rest, window])
        pitfallStack.axis = .vertical
        pitfallStack.spacing = 10
        pitfallStack.translatesAutoresizingMaskIntoConstraints = false
        pitfallCard.addSubview(pitfallStack)

        wishlistButton.addTarget(self, action: #selector(toggleWishlist), for: .touchUpInside)
        addToRouteButton.addTarget(self, action: #selector(addToRoute), for: .touchUpInside)

        let heroWrap = UIView()
        heroWrap.translatesAutoresizingMaskIntoConstraints = false
        heroWrap.addSubview(hero)
        heroWrap.addSubview(overlapCard)
        NSLayoutConstraint.activate([
            hero.topAnchor.constraint(equalTo: heroWrap.topAnchor),
            hero.leadingAnchor.constraint(equalTo: heroWrap.leadingAnchor),
            hero.trailingAnchor.constraint(equalTo: heroWrap.trailingAnchor),
            hero.heightAnchor.constraint(equalToConstant: 240),

            overlapCard.leadingAnchor.constraint(equalTo: heroWrap.leadingAnchor, constant: 14),
            overlapCard.trailingAnchor.constraint(equalTo: heroWrap.trailingAnchor, constant: 10),
            overlapCard.topAnchor.constraint(equalTo: hero.bottomAnchor, constant: 12),
            heroWrap.bottomAnchor.constraint(equalTo: overlapCard.bottomAnchor),

            inner.topAnchor.constraint(equalTo: overlapCard.topAnchor, constant: 16),
            inner.leadingAnchor.constraint(equalTo: overlapCard.leadingAnchor, constant: 16),
            inner.trailingAnchor.constraint(equalTo: overlapCard.trailingAnchor, constant: -16),
            inner.bottomAnchor.constraint(equalTo: overlapCard.bottomAnchor, constant: -16),

            pitfallStack.topAnchor.constraint(equalTo: pitfallCard.topAnchor, constant: 16),
            pitfallStack.leadingAnchor.constraint(equalTo: pitfallCard.leadingAnchor, constant: 16),
            pitfallStack.trailingAnchor.constraint(equalTo: pitfallCard.trailingAnchor, constant: -16),
            pitfallStack.bottomAnchor.constraint(equalTo: pitfallCard.bottomAnchor, constant: -16)
        ])

        [heroWrap, pitfallCard, wishlistButton, addToRouteButton].forEach { contentStack.addArrangedSubview($0) }

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

        navigationController?.navigationBar.tintColor = VelonTheme.primaryDeep
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: VelonTheme.charcoal, .font: UIFont.systemFont(ofSize: 17, weight: .heavy)]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
    }

    private func makeNoteRow(icon: String, title: String, body: String, tint: UIColor) -> UIView {
        let wrap = UIView()
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = tint
        iconView.translatesAutoresizingMaskIntoConstraints = false
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .heavy)
        titleLabel.textColor = VelonTheme.charcoal
        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = .systemFont(ofSize: 14, weight: .medium)
        bodyLabel.textColor = VelonTheme.warmStone
        bodyLabel.numberOfLines = 0
        let text = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        text.axis = .vertical
        text.spacing = 2
        text.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(iconView)
        wrap.addSubview(text)
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            iconView.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 2),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            text.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            text.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            text.topAnchor.constraint(equalTo: wrap.topAnchor),
            text.bottomAnchor.constraint(equalTo: wrap.bottomAnchor)
        ])
        return wrap
    }

    private func refreshWishlistChrome() {
        let on = store.isWishlisted(spot.id)
        wishlistButton.setTitle(on ? "Remove from Wishlist" : "Save to Wishlist", for: .normal)
        wishlistButton.backgroundColor = on ? VelonTheme.mist : VelonTheme.primary
        wishlistButton.setTitleColor(on ? VelonTheme.deepAccent : .white, for: .normal)
        navigationItem.rightBarButtonItem?.image = UIImage(systemName: on ? "heart.fill" : "heart")
        navigationItem.rightBarButtonItem?.tintColor = on ? VelonTheme.primary : VelonTheme.primaryDeep
    }

    @objc private func toggleWishlist() {
        store.toggleWishlist(spot.id)
        refreshWishlistChrome()
        VelonMotion.pop(wishlistButton)
        if let button = navigationItem.rightBarButtonItem?.customView {
            VelonMotion.pop(button)
        }
    }

    @objc private func addToRoute() {
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

        let sheet = UIAlertController(title: "Add to Draft", message: "Choose a route draft.", preferredStyle: .actionSheet)
        sheet.view.tintColor = VelonTheme.primaryDeep
        for draft in drafts {
            sheet.addAction(UIAlertAction(title: draft.title, style: .default, handler: { [weak self] _ in
                guard let self else { return }
                var updated = draft
                if !updated.stops.contains(where: { $0.spotId == self.spot.id }) {
                    let day = updated.stops.map(\.dayIndex).max() ?? 0
                    updated.stops.append(VelonRouteStop(spotId: self.spot.id, dayIndex: day))
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
                cityId: self.spot.cityId,
                title: "\(VelonFoodCatalog.city(id: self.spot.cityId)?.name ?? "City") Draft \(drafts.count + 1)",
                spotIds: [self.spot.id]
            )
            let editor = VelonRouteEditorViewController(draftId: draft.id)
            editor.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(editor, animated: true)
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
}
