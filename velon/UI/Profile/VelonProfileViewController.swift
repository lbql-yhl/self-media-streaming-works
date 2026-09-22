//
//  VelonProfileViewController.swift
//  velon
//

import UIKit

final class VelonProfileViewController: UIViewController {
    private enum VelonProfileDestination {
        case preferences
        case wishlist
        case visitNotes
        case coinShop
        case privacy
        case terms
    }

    private struct VelonProfileRow {
        let title: String
        let subtitle: String
        let symbolName: String
        let tint: UIColor
        let destination: VelonProfileDestination
    }

    private struct VelonProfileSection {
        let title: String
        let rows: [VelonProfileRow]
    }

    private let store = VelonUserStore.shared
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerContainer = UIView()
    private let hero = VelonUIFactory.glassPanel()
    private let coinChip = VelonUIFactory.cardView()
    private let balanceValueLabel = UILabel()
    private let tastesStatLabel = UILabel()
    private let wishlistStatLabel = UILabel()
    private let notesStatLabel = UILabel()
    private let getCoinsButton = VelonUIFactory.primaryButton(title: "Get Coins")
    private var didLayoutHeader = false

    private let sections: [VelonProfileSection] = [
        VelonProfileSection(title: "Your desk", rows: [
            VelonProfileRow(
                title: "Taste Preferences",
                subtitle: "Shape Discover ranking",
                symbolName: "fork.knife",
                tint: VelonTheme.primary,
                destination: .preferences
            ),
            VelonProfileRow(
                title: "Wishlist",
                subtitle: "Spots saved for later",
                symbolName: "heart.fill",
                tint: VelonTheme.saffron,
                destination: .wishlist
            ),
            VelonProfileRow(
                title: "Visit Notes",
                subtitle: "Taste notes after trips",
                symbolName: "square.and.pencil",
                tint: VelonTheme.basil,
                destination: .visitNotes
            ),
            VelonProfileRow(
                title: "Coin Shop",
                subtitle: "Consumable packs only",
                symbolName: "creditcard.fill",
                tint: VelonTheme.plum,
                destination: .coinShop
            )
        ]),
        VelonProfileSection(title: "Policies", rows: [
            VelonProfileRow(
                title: "Privacy Policy",
                subtitle: "Open full policy in browser view",
                symbolName: "lock.shield.fill",
                tint: VelonTheme.warmStone,
                destination: .privacy
            ),
            VelonProfileRow(
                title: "Terms of Use",
                subtitle: "Open full terms in browser view",
                symbolName: "doc.text.fill",
                tint: VelonTheme.warmStone,
                destination: .terms
            )
        ])
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        _ = velonInstallAmbient(.profile)
        setupHero()
        setupTable()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadHeader), name: .velonUserDataDidChange, object: nil)
        reloadHeader()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadHeader()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        VelonMotion.staggerIn(views: [hero, tableView], fromY: 18)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutTableHeaderIfNeeded()
    }

    private func setupHero() {
        headerContainer.backgroundColor = .clear
        hero.translatesAutoresizingMaskIntoConstraints = false
        hero.clipsToBounds = false

        let accentBlob = UIView()
        accentBlob.translatesAutoresizingMaskIntoConstraints = false
        accentBlob.backgroundColor = VelonTheme.primary.withAlphaComponent(0.18)
        accentBlob.layer.cornerRadius = 54
        hero.addSubview(accentBlob)

        let plateMark = UIView()
        plateMark.translatesAutoresizingMaskIntoConstraints = false
        plateMark.backgroundColor = .clear
        plateMark.layer.cornerRadius = 28
        plateMark.layer.borderWidth = 5
        plateMark.layer.borderColor = VelonTheme.primary.withAlphaComponent(0.45).cgColor
        hero.addSubview(plateMark)

        let pill = VelonUIFactory.pillLabel("PALATE", fill: VelonTheme.deepAccent)
        pill.translatesAutoresizingMaskIntoConstraints = false

        let title = VelonUIFactory.heroTitle("Your\npalate desk")
        title.font = .systemFont(ofSize: 30, weight: .black)
        title.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = VelonUIFactory.bodyLabel("Tastes, saves, notes, and coins — kept on this device.")
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        coinChip.translatesAutoresizingMaskIntoConstraints = false
        coinChip.backgroundColor = UIColor.white.withAlphaComponent(0.92)

        let coinIcon = UIImageView(image: UIImage(systemName: "sparkles"))
        coinIcon.translatesAutoresizingMaskIntoConstraints = false
        coinIcon.tintColor = VelonTheme.saffron
        coinIcon.contentMode = .scaleAspectFit

        let coinCaption = UILabel()
        coinCaption.translatesAutoresizingMaskIntoConstraints = false
        coinCaption.text = "Coin balance"
        coinCaption.font = .systemFont(ofSize: 12, weight: .bold)
        coinCaption.textColor = VelonTheme.warmStone

        balanceValueLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceValueLabel.font = .systemFont(ofSize: 28, weight: .black)
        balanceValueLabel.textColor = VelonTheme.deepAccent

        getCoinsButton.translatesAutoresizingMaskIntoConstraints = false
        getCoinsButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .heavy)
        getCoinsButton.addTarget(self, action: #selector(openCoinShop), for: .touchUpInside)

        coinChip.addSubview(coinIcon)
        coinChip.addSubview(coinCaption)
        coinChip.addSubview(balanceValueLabel)
        coinChip.addSubview(getCoinsButton)

        let statsRow = UIStackView(arrangedSubviews: [
            makeStatCard(titleLabel: tastesStatLabel, caption: "Tastes", tint: VelonTheme.primary),
            makeStatCard(titleLabel: wishlistStatLabel, caption: "Wishlist", tint: VelonTheme.saffron),
            makeStatCard(titleLabel: notesStatLabel, caption: "Notes", tint: VelonTheme.basil)
        ])
        statsRow.axis = .horizontal
        statsRow.spacing = 8
        statsRow.distribution = .fillEqually
        statsRow.translatesAutoresizingMaskIntoConstraints = false

        [pill, title, subtitle, coinChip, statsRow].forEach { hero.addSubview($0) }
        headerContainer.addSubview(hero)

        NSLayoutConstraint.activate([
            hero.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 8),
            hero.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            hero.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            hero.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -4),

            accentBlob.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: 28),
            accentBlob.topAnchor.constraint(equalTo: hero.topAnchor, constant: -24),
            accentBlob.widthAnchor.constraint(equalToConstant: 108),
            accentBlob.heightAnchor.constraint(equalToConstant: 108),

            plateMark.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -18),
            plateMark.topAnchor.constraint(equalTo: hero.topAnchor, constant: 18),
            plateMark.widthAnchor.constraint(equalToConstant: 56),
            plateMark.heightAnchor.constraint(equalToConstant: 56),

            pill.topAnchor.constraint(equalTo: hero.topAnchor, constant: 16),
            pill.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 16),
            pill.heightAnchor.constraint(equalToConstant: 22),

            title.topAnchor.constraint(equalTo: pill.bottomAnchor, constant: 10),
            title.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 16),
            title.trailingAnchor.constraint(equalTo: plateMark.leadingAnchor, constant: -10),

            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
            subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            subtitle.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -16),

            coinChip.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 14),
            coinChip.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 12),
            coinChip.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -12),

            coinIcon.leadingAnchor.constraint(equalTo: coinChip.leadingAnchor, constant: 14),
            coinIcon.topAnchor.constraint(equalTo: coinChip.topAnchor, constant: 16),
            coinIcon.widthAnchor.constraint(equalToConstant: 22),
            coinIcon.heightAnchor.constraint(equalToConstant: 22),

            coinCaption.leadingAnchor.constraint(equalTo: coinIcon.trailingAnchor, constant: 8),
            coinCaption.centerYAnchor.constraint(equalTo: coinIcon.centerYAnchor),
            coinCaption.trailingAnchor.constraint(lessThanOrEqualTo: getCoinsButton.leadingAnchor, constant: -8),

            balanceValueLabel.topAnchor.constraint(equalTo: coinIcon.bottomAnchor, constant: 8),
            balanceValueLabel.leadingAnchor.constraint(equalTo: coinChip.leadingAnchor, constant: 14),
            balanceValueLabel.bottomAnchor.constraint(equalTo: coinChip.bottomAnchor, constant: -14),

            getCoinsButton.trailingAnchor.constraint(equalTo: coinChip.trailingAnchor, constant: -12),
            getCoinsButton.centerYAnchor.constraint(equalTo: coinChip.centerYAnchor),
            getCoinsButton.widthAnchor.constraint(equalToConstant: 110),

            statsRow.topAnchor.constraint(equalTo: coinChip.bottomAnchor, constant: 12),
            statsRow.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 12),
            statsRow.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -12),
            statsRow.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -14)
        ])

        plateMark.transform = CGAffineTransform(rotationAngle: 0.18)
    }

    private func layoutTableHeaderIfNeeded() {
        let width = tableView.bounds.width
        guard width > 0 else { return }
        let targetWidth = width
        if didLayoutHeader, abs(headerContainer.bounds.width - targetWidth) < 0.5 {
            return
        }
        headerContainer.frame = CGRect(x: 0, y: 0, width: targetWidth, height: 0)
        headerContainer.setNeedsLayout()
        headerContainer.layoutIfNeeded()
        let height = headerContainer.systemLayoutSizeFitting(
            CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        var frame = headerContainer.frame
        frame.size.height = height
        headerContainer.frame = frame
        tableView.tableHeaderView = headerContainer
        didLayoutHeader = true
    }

    private func makeStatCard(titleLabel: UILabel, caption: String, tint: UIColor) -> UIView {
        let card = VelonUIFactory.cardView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.layer.cornerRadius = 16

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 20, weight: .black)
        titleLabel.textColor = VelonTheme.charcoal
        titleLabel.textAlignment = .center

        let captionLabel = UILabel()
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        captionLabel.text = caption
        captionLabel.font = .systemFont(ofSize: 11, weight: .bold)
        captionLabel.textColor = tint
        captionLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [titleLabel, captionLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 64),
            stack.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: card.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -6)
        ])
        return card
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.register(VelonProfileMenuCell.self, forCellReuseIdentifier: VelonProfileMenuCell.reuseId)
        tableView.register(VelonProfileSectionHeader.self, forHeaderFooterViewReuseIdentifier: VelonProfileSectionHeader.reuseId)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.tableHeaderView = headerContainer
    }

    @objc private func reloadHeader() {
        balanceValueLabel.text = "\(store.coinBalance)"
        tastesStatLabel.text = "\(store.tastePreferences.count)"
        wishlistStatLabel.text = "\(store.wishlistSpotIds.count)"
        notesStatLabel.text = "\(store.allVisitNotes().count)"
        tableView.reloadData()
    }

    @objc private func openCoinShop() {
        VelonMotion.pop(getCoinsButton)
        push(destination: .coinShop)
    }

    private func push(destination: VelonProfileDestination) {
        let page: UIViewController
        switch destination {
        case .preferences:
            page = VelonPreferencesViewController()
        case .wishlist:
            page = VelonWishlistViewController()
        case .visitNotes:
            page = VelonVisitLogViewController()
        case .coinShop:
            page = VelonCoinShopViewController()
        case .privacy:
            page = VelonLegalWebViewController(
                title: "Privacy Policy",
                url: URL(string: "https://bloat.velonn.net/privacy_policy.html")!
            )
        case .terms:
            page = VelonLegalWebViewController(
                title: "Terms of Use",
                url: URL(string: "https://bloat.velonn.net/terms_of_use.html")!
            )
        }
        page.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(page, animated: true)
    }
}

extension VelonProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VelonProfileMenuCell.reuseId, for: indexPath) as? VelonProfileMenuCell else {
            return UITableViewCell()
        }
        let row = sections[indexPath.section].rows[indexPath.row]
        cell.configure(title: row.title, subtitle: row.subtitle, symbolName: row.symbolName, tint: row.tint)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: VelonProfileSectionHeader.reuseId) as? VelonProfileSectionHeader else {
            return nil
        }
        header.configure(title: sections[section].title)
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 36 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath) {
            VelonMotion.pop(cell)
        }
        push(destination: sections[indexPath.section].rows[indexPath.row].destination)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 14)
        UIView.animate(withDuration: 0.38, delay: Double(indexPath.row) * 0.045, usingSpringWithDamping: 0.84, initialSpringVelocity: 0.45) {
            cell.alpha = 1
            cell.transform = .identity
        }
    }
}

final class VelonProfileSectionHeader: UITableViewHeaderFooterView {
    static let reuseId = "VelonProfileSectionHeader"
    private let titleLabel = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 13, weight: .heavy)
        titleLabel.textColor = VelonTheme.warmStone
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(title: String) {
        titleLabel.text = title.uppercased()
    }
}

final class VelonProfileMenuCell: UITableViewCell {
    static let reuseId = "VelonProfileMenuCell"
    private let card = VelonUIFactory.cardView()
    private let iconWrap = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        [card, iconWrap, iconView, titleLabel, subtitleLabel, chevron].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        iconWrap.layer.cornerRadius = 14
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white

        titleLabel.font = .systemFont(ofSize: 16, weight: .heavy)
        titleLabel.textColor = VelonTheme.charcoal
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        subtitleLabel.textColor = VelonTheme.warmStone
        subtitleLabel.numberOfLines = 2
        chevron.tintColor = VelonTheme.warmStone
        chevron.contentMode = .scaleAspectFit

        contentView.addSubview(card)
        card.addSubview(iconWrap)
        iconWrap.addSubview(iconView)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)
        card.addSubview(chevron)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),

            iconWrap.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconWrap.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconWrap.widthAnchor.constraint(equalToConstant: 44),
            iconWrap.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: iconWrap.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconWrap.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: iconWrap.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(title: String, subtitle: String, symbolName: String, tint: UIColor) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        iconWrap.backgroundColor = tint
        iconView.image = UIImage(systemName: symbolName)
        VelonTheme.softShadow(for: iconWrap.layer, radius: 8, opacity: 0.18, y: 4)
    }
}

enum VelonLegalCopy {
    static let privacy = """
    Velon stores your taste preferences, route drafts, wishlist, visit notes, and coin balance on this device only.
    Photos you attach to visit notes stay in the app documents folder on your device.
    Velon does not require an account and does not upload your planning data to a remote server.
    """

    static let terms = """
    Velon is a personal food-trip planning notebook. Spot details are curated samples for planning practice and may not reflect live hours or availability.
    Coin packs are consumable virtual items and do not unlock a subscription membership.
    Use Velon for personal non-commercial trip planning.
    """
}
