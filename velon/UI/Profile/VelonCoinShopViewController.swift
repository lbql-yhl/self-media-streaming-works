//
//  VelonCoinShopViewController.swift
//  velon
//

import UIKit

final class VelonCoinShopViewController: UIViewController {
    private let store = VelonUserStore.shared
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let balanceCard = VelonUIFactory.glassPanel()
    private let balanceLabel = VelonUIFactory.heroTitle("0")
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var isPurchasing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Coin Shop"
        _ = velonInstallAmbient(.profile)
        velonEnableTapToDismissKeyboard()

        balanceCard.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.font = .systemFont(ofSize: 44, weight: .black)
        balanceLabel.textColor = VelonTheme.primaryDeep
        let caption = VelonUIFactory.bodyLabel("Coins are consumable tasting credits stored on this device. There is no membership unlock.")
        caption.translatesAutoresizingMaskIntoConstraints = false
        let pill = VelonUIFactory.pillLabel("BALANCE", fill: VelonTheme.saffron)
        pill.translatesAutoresizingMaskIntoConstraints = false
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = VelonTheme.primaryDeep
        spinner.hidesWhenStopped = true
        balanceCard.addSubview(pill)
        balanceCard.addSubview(balanceLabel)
        balanceCard.addSubview(caption)
        balanceCard.addSubview(spinner)
        view.addSubview(balanceCard)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(VelonCoinPackCell.self, forCellReuseIdentifier: VelonCoinPackCell.reuseId)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            balanceCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            balanceCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            balanceCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            pill.topAnchor.constraint(equalTo: balanceCard.topAnchor, constant: 16),
            pill.leadingAnchor.constraint(equalTo: balanceCard.leadingAnchor, constant: 16),
            pill.heightAnchor.constraint(equalToConstant: 22),
            spinner.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
            spinner.trailingAnchor.constraint(equalTo: balanceCard.trailingAnchor, constant: -16),
            balanceLabel.topAnchor.constraint(equalTo: pill.bottomAnchor, constant: 8),
            balanceLabel.leadingAnchor.constraint(equalTo: pill.leadingAnchor),
            balanceLabel.trailingAnchor.constraint(equalTo: balanceCard.trailingAnchor, constant: -16),
            caption.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 6),
            caption.leadingAnchor.constraint(equalTo: pill.leadingAnchor),
            caption.trailingAnchor.constraint(equalTo: balanceCard.trailingAnchor, constant: -16),
            caption.bottomAnchor.constraint(equalTo: balanceCard.bottomAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: balanceCard.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(refreshBalance), name: .velonUserDataDidChange, object: nil)
        refreshBalance()
        VelonMotion.staggerIn(views: [balanceCard, tableView], fromY: 18)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func refreshBalance() {
        balanceLabel.text = "\(store.coinBalance)"
    }

    private func setPurchasing(_ value: Bool) {
        isPurchasing = value
        if value { spinner.startAnimating() } else { spinner.stopAnimating() }
        tableView.isUserInteractionEnabled = !value
    }
}

extension VelonCoinShopViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        VelonCoinPurchaseService.catalog.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VelonCoinPackCell.reuseId, for: indexPath) as? VelonCoinPackCell else {
            return UITableViewCell()
        }
        cell.configure(product: VelonCoinPurchaseService.catalog[indexPath.row], index: indexPath.row)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !isPurchasing else { return }
        let product = VelonCoinPurchaseService.catalog[indexPath.row]
        setPurchasing(true)
        VelonCoinPurchaseService.shared.purchase(productId: product.productId) { [weak self] result in
            guard let self else { return }
            self.setPurchasing(false)
            self.refreshBalance()
            switch result {
            case .success:
                self.velonShowAlert(title: "Purchase Complete", message: "Coins were added to your balance.")
            case .failure(let error):
                guard let message = error.userMessage else { return }
                self.velonShowAlert(title: "Purchase Unavailable", message: message)
            }
        }
    }
}

final class VelonCoinPackCell: UITableViewCell {
    static let reuseId = "VelonCoinPackCell"
    private let card = VelonUIFactory.cardView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let pricePill = VelonUIFactory.pillLabel("$0")
    private let promoPill = VelonUIFactory.pillLabel("DEAL", fill: VelonTheme.basil)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        [card, iconView, titleLabel, detailLabel, pricePill, promoPill].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        titleLabel.font = .systemFont(ofSize: 17, weight: .heavy)
        titleLabel.textColor = VelonTheme.charcoal
        detailLabel.font = .systemFont(ofSize: 13, weight: .medium)
        detailLabel.textColor = VelonTheme.warmStone
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = VelonTheme.primaryDeep
        iconView.backgroundColor = VelonTheme.mist
        iconView.layer.cornerRadius = 14
        contentView.addSubview(card)
        [iconView, titleLabel, detailLabel, pricePill, promoPill].forEach { card.addSubview($0) }
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: pricePill.leadingAnchor, constant: -8),
            pricePill.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            pricePill.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            pricePill.heightAnchor.constraint(equalToConstant: 28),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            promoPill.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 6),
            promoPill.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            promoPill.heightAnchor.constraint(equalToConstant: 20),
            promoPill.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(product: VelonCoinProduct, index: Int) {
        let symbols = ["fork.knife.circle.fill", "cup.and.saucer.fill", "leaf.circle.fill", "flame.circle.fill"]
        iconView.image = UIImage(systemName: symbols[index % symbols.count])
        titleLabel.text = product.displayName
        detailLabel.text = "\(product.coinAmount) tasting coins"
        pricePill.text = "  \(product.priceText)  "
        let colors = [VelonTheme.primary, VelonTheme.saffron, VelonTheme.plum, VelonTheme.basil]
        pricePill.backgroundColor = colors[index % colors.count]
        promoPill.isHidden = !product.isPromotion
        promoPill.text = "  DEAL  "
    }
}
