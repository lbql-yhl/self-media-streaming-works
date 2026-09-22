//
//  VelonPreferencesViewController.swift
//  velon
//

import UIKit

final class VelonPreferencesViewController: UIViewController {
    private let store = VelonUserStore.shared
    private let collectionView: UICollectionView

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Taste Preferences"
        _ = velonInstallAmbient(.profile)
        let tip = VelonUIFactory.bodyLabel("These tastes rank cities and spots across Discover.")
        tip.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        collectionView.register(VelonTasteChipCell.self, forCellWithReuseIdentifier: VelonTasteChipCell.reuseId)
        view.addSubview(tip)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            tip.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            tip.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tip.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            collectionView.topAnchor.constraint(equalTo: tip.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for (index, tag) in VelonTasteTag.allCases.enumerated() where store.tastePreferences.contains(tag) {
            collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: [])
        }
        VelonMotion.staggerIn(views: collectionView.visibleCells, fromY: 20)
    }
}

extension VelonPreferencesViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        VelonTasteTag.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VelonTasteChipCell.reuseId, for: indexPath) as? VelonTasteChipCell else {
            return UICollectionViewCell()
        }
        let tag = VelonTasteTag.allCases[indexPath.item]
        cell.configure(tag: tag, selected: store.tastePreferences.contains(tag))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 44) / 2
        return CGSize(width: width, height: 88)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        toggle(at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        toggle(at: indexPath)
    }

    private func toggle(at indexPath: IndexPath) {
        let tag = VelonTasteTag.allCases[indexPath.item]
        var set = store.tastePreferences
        if set.contains(tag) { set.remove(tag) } else { set.insert(tag) }
        store.tastePreferences = set
        if let cell = collectionView.cellForItem(at: indexPath) as? VelonTasteChipCell {
            cell.configure(tag: tag, selected: set.contains(tag))
            VelonMotion.pop(cell)
        }
    }
}

final class VelonTasteChipCell: UICollectionViewCell {
    static let reuseId = "VelonTasteChipCell"
    private let card = VelonUIFactory.cardView()
    private let titleLabel = UILabel()
    private let accent = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        card.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        accent.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .heavy)
        titleLabel.textColor = VelonTheme.charcoal
        titleLabel.numberOfLines = 2
        accent.layer.cornerRadius = 4
        contentView.addSubview(card)
        card.addSubview(accent)
        card.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            accent.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            accent.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            accent.widthAnchor.constraint(equalToConstant: 28),
            accent.heightAnchor.constraint(equalToConstant: 8),
            titleLabel.topAnchor.constraint(equalTo: accent.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: accent.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(tag: VelonTasteTag, selected: Bool) {
        titleLabel.text = tag.displayName
        let palette = [VelonTheme.primary, VelonTheme.saffron, VelonTheme.basil, VelonTheme.plum, VelonTheme.coralGlow, VelonTheme.primaryDeep]
        let color = palette[VelonTasteTag.allCases.firstIndex(of: tag) ?? 0]
        accent.backgroundColor = color
        card.backgroundColor = selected ? color.withAlphaComponent(0.18) : VelonTheme.cardBackground
        card.layer.borderColor = selected ? color.cgColor : UIColor.white.withAlphaComponent(0.7).cgColor
        card.layer.borderWidth = selected ? 2 : 1
        titleLabel.textColor = selected ? VelonTheme.deepAccent : VelonTheme.charcoal
    }
}
