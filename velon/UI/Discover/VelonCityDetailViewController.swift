//
//  VelonCityDetailViewController.swift
//  velon
//

import UIKit

final class VelonCityDetailViewController: UIViewController {
    private let city: VelonCity
    private let store = VelonUserStore.shared
    private var spots: [VelonSpot] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let planButton = VelonUIFactory.primaryButton(title: "Build Route Draft")
    private let heroImage = UIImageView()
    private let heroScrim = CAGradientLayer()
    private let heroTitle = UILabel()
    private let heroMeta = UILabel()

    init(city: VelonCity) {
        self.city = city
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = city.name
        view.backgroundColor = VelonTheme.creamSurface
        _ = velonInstallAmbient(.discover)
        spots = VelonFoodCatalog.rankedSpots(inCity: city.id, preferences: store.tastePreferences)
        setupHero()
        setupTable()
        setupPlanButton()
        VelonMotion.staggerIn(views: [heroImage, tableView, planButton], fromY: 30)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        spots = VelonFoodCatalog.rankedSpots(inCity: city.id, preferences: store.tastePreferences)
        tableView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroScrim.frame = heroImage.bounds
    }

    private func setupHero() {
        heroImage.translatesAutoresizingMaskIntoConstraints = false
        VelonImageLoader.apply(to: heroImage, city: city, cornerRadius: 28)
        heroScrim.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.55).cgColor]
        heroScrim.locations = [0.35, 1]
        heroImage.layer.addSublayer(heroScrim)

        heroTitle.translatesAutoresizingMaskIntoConstraints = false
        heroTitle.text = city.name
        heroTitle.font = .systemFont(ofSize: 32, weight: .black)
        heroTitle.textColor = .white

        heroMeta.translatesAutoresizingMaskIntoConstraints = false
        heroMeta.text = "\(city.country)  ·  \(city.signatureTags.prefix(3).map(\.displayName).joined(separator: " · "))"
        heroMeta.font = .systemFont(ofSize: 13, weight: .semibold)
        heroMeta.textColor = UIColor.white.withAlphaComponent(0.9)
        heroMeta.numberOfLines = 2

        let floatingBadge = VelonUIFactory.pillLabel("CITY MENU", fill: VelonTheme.saffron)
        floatingBadge.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(heroImage)
        heroImage.addSubview(heroTitle)
        heroImage.addSubview(heroMeta)
        view.addSubview(floatingBadge)

        NSLayoutConstraint.activate([
            heroImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            heroImage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            heroImage.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            heroImage.heightAnchor.constraint(equalToConstant: 210),

            floatingBadge.topAnchor.constraint(equalTo: heroImage.topAnchor, constant: 16),
            floatingBadge.trailingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: 8),
            floatingBadge.heightAnchor.constraint(equalToConstant: 24),

            heroTitle.leadingAnchor.constraint(equalTo: heroImage.leadingAnchor, constant: 18),
            heroTitle.trailingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: -18),
            heroTitle.bottomAnchor.constraint(equalTo: heroMeta.topAnchor, constant: -4),

            heroMeta.leadingAnchor.constraint(equalTo: heroTitle.leadingAnchor),
            heroMeta.trailingAnchor.constraint(equalTo: heroTitle.trailingAnchor),
            heroMeta.bottomAnchor.constraint(equalTo: heroImage.bottomAnchor, constant: -16)
        ])
        floatingBadge.transform = CGAffineTransform(rotationAngle: 0.12)
        VelonTheme.glowShadow(for: floatingBadge.layer)
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(VelonSpotCell.self, forCellReuseIdentifier: VelonSpotCell.reuseId)
        view.addSubview(tableView)
    }

    private func setupPlanButton() {
        planButton.translatesAutoresizingMaskIntoConstraints = false
        planButton.addTarget(self, action: #selector(buildDraft), for: .touchUpInside)
        view.addSubview(planButton)

        NSLayoutConstraint.activate([
            planButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            planButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            planButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            tableView.topAnchor.constraint(equalTo: heroImage.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: planButton.topAnchor, constant: -10)
        ])
    }

    @objc private func buildDraft() {
        VelonMotion.pop(planButton)
        let topIds = Array(spots.prefix(VelonFoodCatalog.homeSpotLimitPerCity).map(\.id))
        let draft = store.createDraft(cityId: city.id, title: "\(city.name) Draft \(store.drafts(forCity: city.id).count + 1)", spotIds: topIds)
        let editor = VelonRouteEditorViewController(draftId: draft.id)
        editor.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(editor, animated: true)
    }
}

extension VelonCityDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { spots.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VelonSpotCell.reuseId, for: indexPath) as? VelonSpotCell else {
            return UITableViewCell()
        }
        let spot = spots[indexPath.row]
        let hits = VelonFoodCatalog.matchedTags(for: spot, preferences: store.tastePreferences)
        cell.configure(
            spot: spot,
            matchTags: hits,
            zigZag: indexPath.row % 2 == 1,
            wishlisted: store.isWishlisted(spot.id)
        )
        cell.onToggleWishlist = { [weak self] spotId in
            self?.store.toggleWishlist(spotId)
            self?.tableView.reloadRows(at: [indexPath], with: .none)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let spot = spots[indexPath.row]
        let on = store.isWishlisted(spot.id)
        let action = UIContextualAction(style: .normal, title: on ? "Unwish" : "Wishlist") { [weak self] _, _, done in
            self?.store.toggleWishlist(spot.id)
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            done(true)
        }
        action.backgroundColor = VelonTheme.primary
        return UISwipeActionsConfiguration(actions: [action])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detail = VelonSpotDetailViewController(spot: spots[indexPath.row])
        detail.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detail, animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: indexPath.row % 2 == 0 ? -20 : 20, y: 12)
        UIView.animate(withDuration: 0.45, delay: 0.03, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.4) {
            cell.alpha = 1
            cell.transform = .identity
        }
    }
}

final class VelonSpotCell: UITableViewCell {
    static let reuseId = "VelonSpotCell"
    private let card = VelonUIFactory.cardView()
    private let cover = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let matchLabel = UILabel()
    private let wishButton = UIButton(type: .system)
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    private var spotId: String?
    var onToggleWishlist: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        [card, cover, titleLabel, subtitleLabel, matchLabel, wishButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        titleLabel.font = .systemFont(ofSize: 17, weight: .heavy)
        titleLabel.textColor = VelonTheme.charcoal
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = VelonTheme.warmStone
        subtitleLabel.numberOfLines = 2
        matchLabel.font = .systemFont(ofSize: 12, weight: .bold)
        matchLabel.textColor = VelonTheme.primaryDeep

        wishButton.setImage(UIImage(systemName: "heart"), for: .normal)
        wishButton.tintColor = VelonTheme.primary
        wishButton.backgroundColor = VelonTheme.mist
        wishButton.layer.cornerRadius = 18
        wishButton.addTarget(self, action: #selector(wishTapped), for: .touchUpInside)

        contentView.addSubview(card)
        [cover, titleLabel, subtitleLabel, matchLabel, wishButton].forEach { card.addSubview($0) }

        let leading = card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        let trailing = card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        leadingConstraint = leading
        trailingConstraint = trailing

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            leading, trailing,
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            cover.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            cover.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            cover.widthAnchor.constraint(equalToConstant: 86),
            cover.heightAnchor.constraint(equalToConstant: 86),
            cover.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12),

            wishButton.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            wishButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            wishButton.widthAnchor.constraint(equalToConstant: 36),
            wishButton.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.topAnchor.constraint(equalTo: cover.topAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: cover.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: wishButton.leadingAnchor, constant: -8),

            matchLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            matchLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            matchLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: matchLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(spot: VelonSpot, matchTags: [VelonTasteTag], zigZag: Bool = false, wishlisted: Bool = false) {
        spotId = spot.id
        VelonImageLoader.apply(to: cover, named: spot.imageName, cornerRadius: 16)
        titleLabel.text = spot.name
        subtitleLabel.text = "\(spot.district) · \(spot.blurb)"
        matchLabel.text = matchTags.isEmpty
            ? spot.tags.map(\.displayName).joined(separator: " · ")
            : "Matched: " + matchTags.map(\.displayName).joined(separator: ", ")
        wishButton.setImage(UIImage(systemName: wishlisted ? "heart.fill" : "heart"), for: .normal)
        wishButton.tintColor = wishlisted ? .white : VelonTheme.primary
        wishButton.backgroundColor = wishlisted ? VelonTheme.primary : VelonTheme.mist
        leadingConstraint?.constant = zigZag ? 28 : 16
        trailingConstraint?.constant = zigZag ? -16 : -28
    }

    @objc private func wishTapped() {
        guard let spotId else { return }
        VelonMotion.pop(wishButton)
        onToggleWishlist?(spotId)
    }
}
