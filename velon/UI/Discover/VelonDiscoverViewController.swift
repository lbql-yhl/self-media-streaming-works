//
//  VelonDiscoverViewController.swift
//  velon
//

import UIKit

final class VelonDiscoverViewController: UIViewController {
    private let store = VelonUserStore.shared
    private var cities: [VelonCity] = []
    private let collectionView: UICollectionView
    private let preferenceScroll = UIScrollView()
    private let preferenceStack = UIStackView()
    private let heroPanel = VelonUIFactory.glassPanel()
    private let heroTitle = VelonUIFactory.heroTitle("Taste-first\ncities")
    private let heroSubtitle = VelonUIFactory.bodyLabel("Dial your palate. Rank cities by flavor — or tap + to add your own custom city.")
    private let accentSlash = UIView()

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 18
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 28, right: 16)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Discover"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus.circle.fill"), style: .plain, target: self, action: #selector(addCustomCity))
        _ = velonInstallAmbient(.discover)
        setupHero()
        setupPreferences()
        setupCollection()
        reloadContent()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadContent), name: .velonUserDataDidChange, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        VelonMotion.staggerIn(views: [heroPanel, preferenceScroll, collectionView], fromY: 24)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func setupHero() {
        heroPanel.translatesAutoresizingMaskIntoConstraints = false
        heroTitle.translatesAutoresizingMaskIntoConstraints = false
        heroSubtitle.translatesAutoresizingMaskIntoConstraints = false
        accentSlash.translatesAutoresizingMaskIntoConstraints = false
        accentSlash.backgroundColor = VelonTheme.primary
        accentSlash.layer.cornerRadius = 4
        accentSlash.transform = CGAffineTransform(rotationAngle: -0.2)

        let badge = VelonUIFactory.pillLabel("FOOD PLANNER", fill: VelonTheme.saffron)
        badge.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(heroPanel)
        heroPanel.addSubview(accentSlash)
        heroPanel.addSubview(badge)
        heroPanel.addSubview(heroTitle)
        heroPanel.addSubview(heroSubtitle)

        NSLayoutConstraint.activate([
            heroPanel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            heroPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            heroPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            accentSlash.topAnchor.constraint(equalTo: heroPanel.topAnchor, constant: 18),
            accentSlash.trailingAnchor.constraint(equalTo: heroPanel.trailingAnchor, constant: -20),
            accentSlash.widthAnchor.constraint(equalToConstant: 54),
            accentSlash.heightAnchor.constraint(equalToConstant: 10),

            badge.topAnchor.constraint(equalTo: heroPanel.topAnchor, constant: 18),
            badge.leadingAnchor.constraint(equalTo: heroPanel.leadingAnchor, constant: 18),
            badge.heightAnchor.constraint(equalToConstant: 24),

            heroTitle.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 10),
            heroTitle.leadingAnchor.constraint(equalTo: heroPanel.leadingAnchor, constant: 18),
            heroTitle.trailingAnchor.constraint(equalTo: heroPanel.trailingAnchor, constant: -18),

            heroSubtitle.topAnchor.constraint(equalTo: heroTitle.bottomAnchor, constant: 8),
            heroSubtitle.leadingAnchor.constraint(equalTo: heroTitle.leadingAnchor),
            heroSubtitle.trailingAnchor.constraint(equalTo: heroTitle.trailingAnchor),
            heroSubtitle.bottomAnchor.constraint(equalTo: heroPanel.bottomAnchor, constant: -18)
        ])
    }

    private func setupPreferences() {
        preferenceScroll.translatesAutoresizingMaskIntoConstraints = false
        preferenceScroll.showsHorizontalScrollIndicator = false
        preferenceStack.axis = .horizontal
        preferenceStack.spacing = 10
        preferenceStack.translatesAutoresizingMaskIntoConstraints = false
        preferenceScroll.addSubview(preferenceStack)
        view.addSubview(preferenceScroll)

        NSLayoutConstraint.activate([
            preferenceScroll.topAnchor.constraint(equalTo: heroPanel.bottomAnchor, constant: 14),
            preferenceScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            preferenceScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            preferenceScroll.heightAnchor.constraint(equalToConstant: 44),

            preferenceStack.topAnchor.constraint(equalTo: preferenceScroll.topAnchor),
            preferenceStack.bottomAnchor.constraint(equalTo: preferenceScroll.bottomAnchor),
            preferenceStack.leadingAnchor.constraint(equalTo: preferenceScroll.leadingAnchor, constant: 16),
            preferenceStack.trailingAnchor.constraint(equalTo: preferenceScroll.trailingAnchor, constant: -16),
            preferenceStack.heightAnchor.constraint(equalTo: preferenceScroll.heightAnchor)
        ])
        rebuildPreferenceChips()
    }

    private func setupCollection() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(VelonDiscoverCityCard.self, forCellWithReuseIdentifier: VelonDiscoverCityCard.reuseId)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: preferenceScroll.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func rebuildPreferenceChips() {
        preferenceStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let selected = store.tastePreferences
        for (index, tag) in VelonTasteTag.allCases.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(tag.displayName, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .heavy)
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
            button.layer.cornerRadius = 18
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
            let isOn = selected.contains(tag)
            button.backgroundColor = isOn ? VelonTheme.primary : UIColor.white.withAlphaComponent(0.85)
            button.setTitleColor(isOn ? .white : VelonTheme.deepAccent, for: .normal)
            button.layer.borderWidth = isOn ? 0 : 1
            button.layer.borderColor = VelonTheme.separator.cgColor
            if isOn { VelonTheme.glowShadow(for: button.layer) }
            button.tag = index
            button.addTarget(self, action: #selector(togglePreference(_:)), for: .touchUpInside)
            preferenceStack.addArrangedSubview(button)
        }
    }

    @objc private func togglePreference(_ sender: UIButton) {
        let tag = VelonTasteTag.allCases[sender.tag]
        var set = store.tastePreferences
        if set.contains(tag) { set.remove(tag) } else { set.insert(tag) }
        store.tastePreferences = set
        VelonMotion.pop(sender)
    }

    @objc private func addCustomCity() {
        let composer = VelonCustomCityComposerViewController()
        composer.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(composer, animated: true)
    }

    @objc private func reloadContent() {
        cities = VelonCityLookup.discoverCities(preferences: store.tastePreferences)
        rebuildPreferenceChips()
        collectionView.reloadData()
    }
}

extension VelonDiscoverViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cities.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VelonDiscoverCityCard.reuseId, for: indexPath) as? VelonDiscoverCityCard else {
            return UICollectionViewCell()
        }
        let city = cities[indexPath.item]
        let score = VelonFoodCatalog.cityMatchScore(city: city, preferences: store.tastePreferences)
        cell.configure(city: city, matchScore: score, hasPreferences: !store.tastePreferences.isEmpty, offsetStyle: indexPath.item % 2 == 1)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 32
        return CGSize(width: width, height: indexPath.item % 3 == 0 ? 210 : 168)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let detail = VelonCityDetailViewController(city: cities[indexPath.item])
        detail.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detail, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 24).rotated(by: indexPath.item % 2 == 0 ? -0.02 : 0.02)
        UIView.animate(withDuration: 0.5, delay: 0.02, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            cell.alpha = 1
            cell.transform = .identity
        }
    }
}

final class VelonDiscoverCityCard: UICollectionViewCell {
    static let reuseId = "VelonDiscoverCityCard"
    private let card = VelonUIFactory.cardView()
    private let cover = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let matchPill = VelonUIFactory.pillLabel("Match", fill: VelonTheme.primary)
    private let routeRibbon = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        card.translatesAutoresizingMaskIntoConstraints = false
        cover.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        matchPill.translatesAutoresizingMaskIntoConstraints = false
        routeRibbon.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 22, weight: .black)
        titleLabel.textColor = VelonTheme.charcoal
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = VelonTheme.warmStone
        subtitleLabel.numberOfLines = 3
        routeRibbon.backgroundColor = VelonTheme.saffron
        routeRibbon.layer.cornerRadius = 3

        contentView.addSubview(card)
        [cover, titleLabel, subtitleLabel, matchPill, routeRibbon].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            cover.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            cover.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            cover.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            cover.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.38),

            routeRibbon.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            routeRibbon.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            routeRibbon.widthAnchor.constraint(equalToConstant: 42),
            routeRibbon.heightAnchor.constraint(equalToConstant: 6),

            matchPill.topAnchor.constraint(equalTo: routeRibbon.bottomAnchor, constant: 10),
            matchPill.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            matchPill.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.topAnchor.constraint(equalTo: cover.topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: cover.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: matchPill.leadingAnchor, constant: -8),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(city: VelonCity, matchScore: Int, hasPreferences: Bool, offsetStyle: Bool) {
        VelonImageLoader.apply(to: cover, city: city, cornerRadius: 18)
        titleLabel.text = city.name
        subtitleLabel.text = "\(city.country)\n\(city.summary)"
        if city.isCustom {
            matchPill.text = "  CUSTOM  "
            matchPill.backgroundColor = VelonTheme.saffron
        } else if hasPreferences {
            matchPill.text = "  Match \(matchScore)  "
            matchPill.backgroundColor = matchScore > 0 ? VelonTheme.primary : VelonTheme.warmStone
        } else {
            matchPill.text = "  Set tastes  "
            matchPill.backgroundColor = VelonTheme.saffron
        }
        card.transform = offsetStyle ? CGAffineTransform(translationX: 8, y: 0) : CGAffineTransform(translationX: -4, y: 0)
    }
}
