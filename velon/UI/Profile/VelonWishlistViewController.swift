//
//  VelonWishlistViewController.swift
//  velon
//

import UIKit

final class VelonWishlistViewController: UIViewController {
    private let store = VelonUserStore.shared
    private var spots: [VelonSpot] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyPanel = VelonUIFactory.glassPanel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Wishlist"
        _ = velonInstallAmbient(.profile)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(VelonSpotCell.self, forCellReuseIdentifier: VelonSpotCell.reuseId)
        view.addSubview(tableView)

        emptyPanel.translatesAutoresizingMaskIntoConstraints = false
        let empty = VelonUIFactory.bodyLabel("Your wishlist is empty.\nIn a city menu, tap the heart on a spot — or open detail and tap Save to Wishlist.")
        empty.textAlignment = .center
        empty.translatesAutoresizingMaskIntoConstraints = false
        emptyPanel.addSubview(empty)
        view.addSubview(emptyPanel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyPanel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            emptyPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            empty.topAnchor.constraint(equalTo: emptyPanel.topAnchor, constant: 24),
            empty.leadingAnchor.constraint(equalTo: emptyPanel.leadingAnchor, constant: 16),
            empty.trailingAnchor.constraint(equalTo: emptyPanel.trailingAnchor, constant: -16),
            empty.bottomAnchor.constraint(equalTo: emptyPanel.bottomAnchor, constant: -24)
        ])
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .velonUserDataDidChange, object: nil)
        reload()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func reload() {
        spots = store.wishlistSpotIds.compactMap { VelonPlaceLookup.spot(id: $0) }
        emptyPanel.isHidden = !spots.isEmpty
        tableView.reloadData()
    }
}

extension VelonWishlistViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { spots.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VelonSpotCell.reuseId, for: indexPath) as? VelonSpotCell else {
            return UITableViewCell()
        }
        cell.configure(spot: spots[indexPath.row], matchTags: [], zigZag: indexPath.row % 2 == 1, wishlisted: true)
        cell.onToggleWishlist = { [weak self] spotId in
            self?.store.toggleWishlist(spotId)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let spot = spots[indexPath.row]
        VelonPlaceLookup.openDetail(spotId: spot.id, from: self)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let remove = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, done in
            guard let self else { done(false); return }
            self.store.toggleWishlist(self.spots[indexPath.row].id)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [remove])
    }
}
