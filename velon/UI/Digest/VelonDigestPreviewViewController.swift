//
//  VelonDigestPreviewViewController.swift
//  velon
//

import UIKit

final class VelonDigestPreviewViewController: UIViewController {
    private let draft: VelonRouteDraft
    private var notes: [VelonVisitNote]
    private var pages: [UIImage] = []
    private let collectionView: UICollectionView
    private let pageLabel = UILabel()
    private let hintLabel = VelonUIFactory.bodyLabel("")
    private let addContentButton = VelonUIFactory.primaryButton(title: "Add Note & Photo")
    private let shareButton = VelonUIFactory.secondaryButton(title: "Share Current Card")
    private let shareAllButton = VelonUIFactory.secondaryButton(title: "Share Full Album · 10 coins")
    private let noteComposer = VelonVisitNoteComposer()

    init(draft: VelonRouteDraft, notes: [VelonVisitNote]) {
        self.draft = draft
        self.notes = notes
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Album Preview"
        _ = velonInstallAmbient(.digest)
        rebuildPages()

        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        pageLabel.font = .systemFont(ofSize: 14, weight: .heavy)
        pageLabel.textColor = VelonTheme.deepAccent
        pageLabel.textAlignment = .center

        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        refreshHint()

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.decelerationRate = .fast
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(VelonDigestPageCell.self, forCellWithReuseIdentifier: VelonDigestPageCell.reuseId)

        addContentButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        shareAllButton.translatesAutoresizingMaskIntoConstraints = false
        addContentButton.addTarget(self, action: #selector(addContent), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareCurrent), for: .touchUpInside)
        shareAllButton.addTarget(self, action: #selector(shareAll), for: .touchUpInside)

        let actions = UIStackView(arrangedSubviews: [addContentButton, shareButton, shareAllButton])
        actions.axis = .vertical
        actions.spacing = 8
        actions.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(hintLabel)
        view.addSubview(collectionView)
        view.addSubview(pageLabel)
        view.addSubview(actions)

        NSLayoutConstraint.activate([
            hintLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            collectionView.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: pageLabel.topAnchor, constant: -8),

            pageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            pageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            pageLabel.bottomAnchor.constraint(equalTo: actions.topAnchor, constant: -10),

            actions.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actions.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actions.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])

        noteComposer.onFinished = { [weak self] in
            self?.reloadNotesAndPages()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(reloadNotesAndPages), name: .velonUserDataDidChange, object: nil)

        updatePageLabel()
        VelonMotion.staggerIn(views: [hintLabel, collectionView, actions], fromY: 20)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let width = collectionView.bounds.width - 40
            let height = collectionView.bounds.height
            let itemSize = CGSize(width: max(width, 120), height: max(height, 160))
            if layout.itemSize != itemSize {
                layout.itemSize = itemSize
                layout.invalidateLayout()
            }
        }
    }

    private func rebuildPages() {
        pages = VelonDigestCardRenderer.albumImages(draft: draft, notes: notes)
        collectionView.reloadData()
        refreshHint()
        updatePageLabel()
    }

    @objc private func reloadNotesAndPages() {
        notes = VelonUserStore.shared.visitNotes(forDraftId: draft.id)
        rebuildPages()
    }

    private func refreshHint() {
        if notes.isEmpty {
            hintLabel.text = "No notes yet. Tap a card for detail, or Add Note & Photo below."
        } else {
            hintLabel.text = "Swipe the album · tap a card for full detail · add more notes anytime."
        }
    }

    private func openPageDetail(at index: Int) {
        guard pages.indices.contains(index) else { return }
        let note: VelonVisitNote?
        if index == 0 {
            note = nil
        } else {
            let noteIndex = index - 1
            note = notes.indices.contains(noteIndex) ? notes[noteIndex] : nil
        }
        let detail = VelonDigestPageDetailViewController(
            draft: draft,
            pageIndex: index,
            pageImage: pages[index],
            note: note
        )
        detail.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detail, animated: true)
    }

    private func currentIndex() -> Int {
        let centerX = collectionView.contentOffset.x + collectionView.bounds.width / 2
        let indexPath = collectionView.indexPathForItem(at: CGPoint(x: centerX, y: collectionView.bounds.midY))
        return indexPath?.item ?? 0
    }

    private func updatePageLabel() {
        guard !pages.isEmpty else {
            pageLabel.text = "No pages"
            return
        }
        let index = min(max(currentIndex(), 0), pages.count - 1)
        let title = index == 0 ? "Cover" : "Note \(index)"
        pageLabel.text = "\(title)  ·  \(index + 1)/\(pages.count)  ·  Tap for detail"
    }

    @objc private func addContent() {
        VelonMotion.pop(addContentButton)
        noteComposer.start(from: self, draft: draft)
    }

    @objc private func shareCurrent() {
        guard !pages.isEmpty else { return }
        VelonMotion.pop(shareButton)
        presentShare(items: [pages[currentIndex()]])
    }

    @objc private func shareAll() {
        guard !pages.isEmpty else { return }
        VelonMotion.pop(shareAllButton)
        let cost = VelonCoinEconomy.digestAlbumShareCost
        let balance = VelonUserStore.shared.coinBalance
        let alert = UIAlertController(
            title: "Share Full Album",
            message: "Exporting the full digest album costs \(cost) coins each time. Your balance is \(balance) coins.",
            preferredStyle: .alert
        )
        alert.view.tintColor = VelonTheme.primaryDeep
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Spend \(cost) Coins", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            if VelonUserStore.shared.spendCoins(cost) {
                self.presentShare(items: self.pages)
            } else {
                let shop = UIAlertController(
                    title: "Not Enough Coins",
                    message: "You need \(cost) coins to share the full album. Get more in Coin Shop.",
                    preferredStyle: .alert
                )
                shop.view.tintColor = VelonTheme.primaryDeep
                shop.addAction(UIAlertAction(title: "Not Now", style: .cancel))
                shop.addAction(UIAlertAction(title: "Coin Shop", style: .default, handler: { [weak self] _ in
                    let page = VelonCoinShopViewController()
                    page.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(page, animated: true)
                }))
                self.present(shop, animated: true)
            }
        }))
        present(alert, animated: true)
    }

    private func presentShare(items: [Any]) {
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let pop = activity.popoverPresentationController {
            pop.sourceView = shareButton
            pop.sourceRect = shareButton.bounds
        }
        present(activity, animated: true)
    }
}

extension VelonDigestPreviewViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        pages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VelonDigestPageCell.reuseId, for: indexPath) as? VelonDigestPageCell else {
            return UICollectionViewCell()
        }
        cell.configure(image: pages[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openPageDetail(at: indexPath.item)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePageLabel()
    }
}

final class VelonDigestPageCell: UICollectionViewCell {
    static let reuseId = "VelonDigestPageCell"
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 22
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        VelonTheme.softShadow(for: contentView.layer, radius: 16, opacity: 0.16, y: 10)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(image: UIImage) {
        imageView.image = image
    }
}
