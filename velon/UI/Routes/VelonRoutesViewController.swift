//
//  VelonRoutesViewController.swift
//  velon
//

import UIKit

final class VelonRoutesViewController: UIViewController {
    private let store = VelonUserStore.shared
    private var drafts: [VelonRouteDraft] = []
    private var customPlaces: [VelonSpot] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyPanel = VelonUIFactory.glassPanel()
    private let hero = VelonUIFactory.glassPanel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Routes"
        _ = velonInstallAmbient(.routes)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus.circle.fill"), style: .plain, target: self, action: #selector(showAddMenu))

        setupHero()
        setupTable()
        setupEmpty()
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .velonUserDataDidChange, object: nil)
        reload()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        VelonMotion.staggerIn(views: [hero, tableView], fromY: 20)
    }

    private func setupHero() {
        hero.translatesAutoresizingMaskIntoConstraints = false
        let title = VelonUIFactory.heroTitle("Food\ntrajectories")
        title.font = .systemFont(ofSize: 30, weight: .black)
        title.translatesAutoresizingMaskIntoConstraints = false
        let sub = VelonUIFactory.bodyLabel("Draft tasting days, add custom places, then open any stop detail.")
        sub.translatesAutoresizingMaskIntoConstraints = false
        let ribbon = UIView()
        ribbon.backgroundColor = VelonTheme.saffron
        ribbon.layer.cornerRadius = 4
        ribbon.translatesAutoresizingMaskIntoConstraints = false
        ribbon.transform = CGAffineTransform(rotationAngle: -0.15)

        hero.addSubview(title)
        hero.addSubview(sub)
        hero.addSubview(ribbon)
        view.addSubview(hero)

        NSLayoutConstraint.activate([
            hero.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            hero.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            hero.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            ribbon.topAnchor.constraint(equalTo: hero.topAnchor, constant: 20),
            ribbon.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -18),
            ribbon.widthAnchor.constraint(equalToConstant: 56),
            ribbon.heightAnchor.constraint(equalToConstant: 10),

            title.topAnchor.constraint(equalTo: hero.topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 18),
            title.trailingAnchor.constraint(equalTo: ribbon.leadingAnchor, constant: -8),

            sub.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            sub.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            sub.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -18),
            sub.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -16)
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(VelonRouteDraftCell.self, forCellReuseIdentifier: VelonRouteDraftCell.reuseId)
        tableView.register(VelonCustomPlaceCell.self, forCellReuseIdentifier: VelonCustomPlaceCell.reuseId)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: hero.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmpty() {
        emptyPanel.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(systemName: "map.circle.fill"))
        icon.tintColor = VelonTheme.primary
        icon.translatesAutoresizingMaskIntoConstraints = false
        let label = VelonUIFactory.bodyLabel("No drafts or custom places yet.\nTap + to create a route or add your own stop.")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        emptyPanel.addSubview(icon)
        emptyPanel.addSubview(label)
        view.addSubview(emptyPanel)
        NSLayoutConstraint.activate([
            emptyPanel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40),
            emptyPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            emptyPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            icon.topAnchor.constraint(equalTo: emptyPanel.topAnchor, constant: 22),
            icon.centerXAnchor.constraint(equalTo: emptyPanel.centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: 48),
            icon.heightAnchor.constraint(equalToConstant: 48),
            label.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: emptyPanel.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: emptyPanel.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: emptyPanel.bottomAnchor, constant: -22)
        ])
    }

    @objc private func reload() {
        drafts = store.allDrafts().sorted { $0.updatedAt > $1.updatedAt }
        customPlaces = store.allCustomPlaces()
        emptyPanel.isHidden = !(drafts.isEmpty && customPlaces.isEmpty)
        tableView.reloadData()
    }

    @objc private func showAddMenu() {
        let sheet = UIAlertController(title: "Add", message: nil, preferredStyle: .actionSheet)
        sheet.view.tintColor = VelonTheme.primaryDeep
        sheet.addAction(UIAlertAction(title: "New Route Draft", style: .default, handler: { [weak self] _ in
            self?.createFromWishlistOrCity()
        }))
        sheet.addAction(UIAlertAction(title: "Add Custom Place", style: .default, handler: { [weak self] _ in
            let composer = VelonCustomPlaceComposerViewController()
            composer.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(composer, animated: true)
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func createFromWishlistOrCity() {
        let sheet = UIAlertController(title: "New Route Draft", message: "Choose a city to start.", preferredStyle: .actionSheet)
        sheet.view.tintColor = VelonTheme.primaryDeep
        for city in VelonCityLookup.allCities() {
            sheet.addAction(UIAlertAction(title: city.name, style: .default, handler: { [weak self] _ in
                guard let self else { return }
                let wish = self.store.wishlistSpotIds.filter { VelonPlaceLookup.spot(id: $0)?.cityId == city.id }
                let seed = wish.isEmpty ? Array(VelonPlaceLookup.spots(inCity: city.id).prefix(3).map(\.id)) : wish
                let draft = self.store.createDraft(cityId: city.id, title: "\(city.name) Draft", spotIds: seed)
                let editor = VelonRouteEditorViewController(draftId: draft.id)
                editor.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(editor, animated: true)
            }))
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
}

extension VelonRoutesViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? drafts.count : customPlaces.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return drafts.isEmpty ? nil : "Route Drafts"
        }
        return customPlaces.isEmpty ? nil : "Custom Places"
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = .systemFont(ofSize: 14, weight: .heavy)
        header.textLabel?.textColor = VelonTheme.deepAccent
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: VelonRouteDraftCell.reuseId, for: indexPath) as? VelonRouteDraftCell else {
                return UITableViewCell()
            }
            cell.configure(draft: drafts[indexPath.row], index: indexPath.row)
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VelonCustomPlaceCell.reuseId, for: indexPath) as? VelonCustomPlaceCell else {
            return UITableViewCell()
        }
        cell.configure(place: customPlaces[indexPath.row], index: indexPath.row)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let editor = VelonRouteEditorViewController(draftId: drafts[indexPath.row].id)
            editor.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(editor, animated: true)
        } else {
            VelonPlaceLookup.openDetail(spotId: customPlaces[indexPath.row].id, from: self)
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 0 {
            let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
                guard let self else { done(false); return }
                self.store.deleteDraft(id: self.drafts[indexPath.row].id)
                done(true)
            }
            return UISwipeActionsConfiguration(actions: [delete])
        }
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self else { done(false); return }
            self.store.deleteCustomPlace(id: self.customPlaces[indexPath.row].id)
            done(true)
        }
        let open = UIContextualAction(style: .normal, title: "Detail") { [weak self] _, _, done in
            guard let self else { done(false); return }
            VelonPlaceLookup.openDetail(spotId: self.customPlaces[indexPath.row].id, from: self)
            done(true)
        }
        open.backgroundColor = VelonTheme.primary
        return UISwipeActionsConfiguration(actions: [delete, open])
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 18)
        UIView.animate(withDuration: 0.4, delay: Double(indexPath.row) * 0.04, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4) {
            cell.alpha = 1
            cell.transform = .identity
        }
    }
}

final class VelonRouteDraftCell: UITableViewCell {
    static let reuseId = "VelonRouteDraftCell"
    private let card = VelonUIFactory.cardView()
    private let cover = UIImageView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let statusPill = VelonUIFactory.pillLabel("draft")
    private let stopsChip = VelonUIFactory.pillLabel("0", fill: VelonTheme.mist, textColor: VelonTheme.deepAccent)
    private let daysChip = VelonUIFactory.pillLabel("0", fill: VelonTheme.mist, textColor: VelonTheme.deepAccent)
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let accentBar = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        [card, cover, titleLabel, metaLabel, statusPill, stopsChip, daysChip, chevron, accentBar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        titleLabel.font = .systemFont(ofSize: 18, weight: .heavy)
        titleLabel.textColor = VelonTheme.charcoal
        metaLabel.font = .systemFont(ofSize: 13, weight: .medium)
        metaLabel.textColor = VelonTheme.warmStone
        metaLabel.numberOfLines = 2
        chevron.tintColor = VelonTheme.warmStone
        chevron.contentMode = .scaleAspectFit
        accentBar.layer.cornerRadius = 3
        cover.contentMode = .scaleAspectFill
        cover.clipsToBounds = true
        cover.layer.cornerRadius = 16
        cover.backgroundColor = VelonTheme.separator

        let chipRow = UIStackView(arrangedSubviews: [stopsChip, daysChip])
        chipRow.axis = .horizontal
        chipRow.spacing = 6
        chipRow.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(card)
        [accentBar, cover, titleLabel, metaLabel, statusPill, chipRow, chevron].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            accentBar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            accentBar.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            accentBar.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            accentBar.widthAnchor.constraint(equalToConstant: 6),

            cover.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 10),
            cover.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            cover.widthAnchor.constraint(equalToConstant: 76),
            cover.heightAnchor.constraint(equalToConstant: 76),
            cover.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12),

            statusPill.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            statusPill.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            statusPill.heightAnchor.constraint(equalToConstant: 22),

            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 10),
            chevron.heightAnchor.constraint(equalToConstant: 14),

            titleLabel.topAnchor.constraint(equalTo: cover.topAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: cover.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: statusPill.leadingAnchor, constant: -8),

            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            chipRow.topAnchor.constraint(equalTo: metaLabel.bottomAnchor, constant: 8),
            chipRow.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            chipRow.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12),
            stopsChip.heightAnchor.constraint(equalToConstant: 22),
            daysChip.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(draft: VelonRouteDraft, index: Int) {
        let city = VelonCityLookup.city(id: draft.cityId)
        if let city {
            VelonImageLoader.apply(to: cover, city: city, cornerRadius: 16)
        } else {
            cover.image = nil
        }
        titleLabel.text = draft.title
        metaLabel.text = "\(city?.name ?? draft.cityId) · tasting route"
        stopsChip.text = "  \(draft.spotCount) stops  "
        daysChip.text = "  \(draft.dayCount) day(s)  "
        statusPill.text = "  \(draft.status.rawValue.uppercased())  "
        switch draft.status {
        case .selected:
            statusPill.backgroundColor = VelonTheme.basil
            accentBar.backgroundColor = VelonTheme.basil
        case .archived:
            statusPill.backgroundColor = VelonTheme.warmStone
            accentBar.backgroundColor = VelonTheme.warmStone
        case .draft:
            statusPill.backgroundColor = VelonTheme.primary
            accentBar.backgroundColor = index % 2 == 0 ? VelonTheme.primary : VelonTheme.saffron
        }
    }
}

final class VelonCustomPlaceCell: UITableViewCell {
    static let reuseId = "VelonCustomPlaceCell"
    private let card = VelonUIFactory.cardView()
    private let cover = UIImageView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let pill = VelonUIFactory.pillLabel("CUSTOM", fill: VelonTheme.saffron)
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        [card, cover, titleLabel, metaLabel, pill, chevron].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        titleLabel.font = .systemFont(ofSize: 17, weight: .heavy)
        titleLabel.textColor = VelonTheme.charcoal
        metaLabel.font = .systemFont(ofSize: 13, weight: .medium)
        metaLabel.textColor = VelonTheme.warmStone
        metaLabel.numberOfLines = 2
        chevron.tintColor = VelonTheme.warmStone
        chevron.contentMode = .scaleAspectFit
        contentView.addSubview(card)
        [cover, titleLabel, metaLabel, pill, chevron].forEach { card.addSubview($0) }
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cover.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            cover.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            cover.widthAnchor.constraint(equalToConstant: 78),
            cover.heightAnchor.constraint(equalToConstant: 78),
            cover.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12),
            pill.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            pill.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            pill.heightAnchor.constraint(equalToConstant: 22),
            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 10),
            chevron.heightAnchor.constraint(equalToConstant: 14),
            titleLabel.topAnchor.constraint(equalTo: cover.topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: cover.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: pill.leadingAnchor, constant: -8),
            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            metaLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(place: VelonSpot, index: Int) {
        VelonImageLoader.apply(to: cover, named: place.imageName, cornerRadius: 16)
        titleLabel.text = place.name
        let city = VelonCityLookup.city(id: place.cityId)?.name ?? place.cityId
        metaLabel.text = "\(city) · \(place.district)"
        _ = index
    }
}
