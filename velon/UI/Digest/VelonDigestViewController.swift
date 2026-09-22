//
//  VelonDigestViewController.swift
//  velon
//

import UIKit

final class VelonDigestViewController: UIViewController {
    private let store = VelonUserStore.shared
    private var drafts: [VelonRouteDraft] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let hero = VelonUIFactory.glassPanel()
    private let emptyPanel = VelonUIFactory.glassPanel()
    private let noteComposer = VelonVisitNoteComposer()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Digest"
        _ = velonInstallAmbient(.digest)
        setupHero()
        setupTable()
        setupEmpty()
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .velonUserDataDidChange, object: nil)
        noteComposer.onFinished = { [weak self] in
            self?.reload()
        }
        reload()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        VelonMotion.staggerIn(views: [hero, tableView], fromY: 18)
    }

    private func setupHero() {
        hero.translatesAutoresizingMaskIntoConstraints = false
        let title = VelonUIFactory.heroTitle("Post-trip\ndigest")
        title.font = .systemFont(ofSize: 30, weight: .black)
        title.translatesAutoresizingMaskIntoConstraints = false
        let sub = VelonUIFactory.bodyLabel("Open a route album, add taste notes with photos, then share your booklet.")
        sub.translatesAutoresizingMaskIntoConstraints = false
        let pill = VelonUIFactory.pillLabel("ALBUM", fill: VelonTheme.plum)
        pill.translatesAutoresizingMaskIntoConstraints = false
        hero.addSubview(title)
        hero.addSubview(sub)
        hero.addSubview(pill)
        view.addSubview(hero)
        NSLayoutConstraint.activate([
            hero.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            hero.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            hero.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            pill.topAnchor.constraint(equalTo: hero.topAnchor, constant: 16),
            pill.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -16),
            pill.heightAnchor.constraint(equalToConstant: 22),
            title.topAnchor.constraint(equalTo: hero.topAnchor, constant: 14),
            title.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 16),
            title.trailingAnchor.constraint(equalTo: pill.leadingAnchor, constant: -8),
            sub.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            sub.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            sub.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -16),
            sub.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -16)
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(VelonDigestDraftCell.self, forCellReuseIdentifier: VelonDigestDraftCell.reuseId)
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
        let label = VelonUIFactory.bodyLabel("No route drafts yet.\nBuild a route and add visit notes, then come back to generate your digest.")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        emptyPanel.addSubview(label)
        view.addSubview(emptyPanel)
        NSLayoutConstraint.activate([
            emptyPanel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 36),
            emptyPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            emptyPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            label.topAnchor.constraint(equalTo: emptyPanel.topAnchor, constant: 22),
            label.leadingAnchor.constraint(equalTo: emptyPanel.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: emptyPanel.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: emptyPanel.bottomAnchor, constant: -22)
        ])
    }

    @objc private func reload() {
        drafts = store.allDrafts().sorted { $0.updatedAt > $1.updatedAt }
        emptyPanel.isHidden = !drafts.isEmpty
        tableView.reloadData()
    }

    private func openPreview(for draft: VelonRouteDraft) {
        let notes = store.visitNotes(forDraftId: draft.id)
        let preview = VelonDigestPreviewViewController(draft: draft, notes: notes)
        preview.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(preview, animated: true)
    }

    private func addNote(for draft: VelonRouteDraft) {
        noteComposer.start(from: self, draft: draft)
    }
}

extension VelonDigestViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { drafts.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VelonDigestDraftCell.reuseId, for: indexPath) as? VelonDigestDraftCell else {
            return UITableViewCell()
        }
        let draft = drafts[indexPath.row]
        let notes = store.visitNotes(forDraftId: draft.id)
        cell.configure(draft: draft, noteCount: notes.count, photoCount: notes.filter { $0.photoRelativePath != nil }.count)
        cell.onAddNote = { [weak self] in
            self?.addNote(for: draft)
        }
        cell.onOpenAlbum = { [weak self] in
            self?.openPreview(for: draft)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openPreview(for: drafts[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let add = UIContextualAction(style: .normal, title: "Add Note") { [weak self] _, _, done in
            guard let self else { done(false); return }
            self.addNote(for: self.drafts[indexPath.row])
            done(true)
        }
        add.backgroundColor = VelonTheme.primary
        return UISwipeActionsConfiguration(actions: [add])
    }
}

final class VelonDigestDraftCell: UITableViewCell {
    static let reuseId = "VelonDigestDraftCell"
    private let card = VelonUIFactory.cardView()
    private let cover = UIImageView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let pill = VelonUIFactory.pillLabel("DIGEST", fill: VelonTheme.plum)
    private let notesChip = VelonUIFactory.pillLabel("0 notes", fill: VelonTheme.mist, textColor: VelonTheme.deepAccent)
    private let photosChip = VelonUIFactory.pillLabel("0 photos", fill: VelonTheme.mist, textColor: VelonTheme.deepAccent)
    private let addNoteButton = VelonUIFactory.primaryButton(title: "Add Note")
    private let albumButton = VelonUIFactory.secondaryButton(title: "Open Album")
    var onAddNote: (() -> Void)?
    var onOpenAlbum: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        [card, cover, titleLabel, metaLabel, pill, notesChip, photosChip, addNoteButton, albumButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        titleLabel.font = .systemFont(ofSize: 18, weight: .heavy)
        titleLabel.textColor = VelonTheme.charcoal
        metaLabel.font = .systemFont(ofSize: 13, weight: .medium)
        metaLabel.textColor = VelonTheme.warmStone
        metaLabel.numberOfLines = 2
        cover.contentMode = .scaleAspectFill
        cover.clipsToBounds = true
        cover.layer.cornerRadius = 16
        cover.backgroundColor = VelonTheme.separator
        addNoteButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        albumButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        addNoteButton.addTarget(self, action: #selector(addNoteTapped), for: .touchUpInside)
        albumButton.addTarget(self, action: #selector(albumTapped), for: .touchUpInside)

        let chipRow = UIStackView(arrangedSubviews: [notesChip, photosChip])
        chipRow.axis = .horizontal
        chipRow.spacing = 6
        chipRow.translatesAutoresizingMaskIntoConstraints = false

        let actions = UIStackView(arrangedSubviews: [addNoteButton, albumButton])
        actions.axis = .horizontal
        actions.spacing = 8
        actions.distribution = .fillEqually
        actions.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(card)
        [cover, titleLabel, metaLabel, pill, chipRow, actions].forEach { card.addSubview($0) }
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            cover.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            cover.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            cover.widthAnchor.constraint(equalToConstant: 84),
            cover.heightAnchor.constraint(equalToConstant: 84),

            pill.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            pill.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            pill.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.topAnchor.constraint(equalTo: cover.topAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: cover.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: pill.leadingAnchor, constant: -8),

            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            chipRow.topAnchor.constraint(equalTo: metaLabel.bottomAnchor, constant: 8),
            chipRow.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            chipRow.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -14),
            notesChip.heightAnchor.constraint(equalToConstant: 22),
            photosChip.heightAnchor.constraint(equalToConstant: 22),

            actions.topAnchor.constraint(equalTo: cover.bottomAnchor, constant: 12),
            actions.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            actions.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            actions.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            addNoteButton.heightAnchor.constraint(equalToConstant: 42),
            albumButton.heightAnchor.constraint(equalToConstant: 42)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(draft: VelonRouteDraft, noteCount: Int, photoCount: Int) {
        let city = VelonCityLookup.city(id: draft.cityId)
        if let city {
            VelonImageLoader.apply(to: cover, city: city, cornerRadius: 16)
        } else {
            cover.image = nil
        }
        titleLabel.text = draft.title
        metaLabel.text = "\(city?.name ?? draft.cityId) · \(draft.spotCount) stops"
        notesChip.text = "  \(noteCount) notes  "
        photosChip.text = "  \(photoCount) photos  "
        if noteCount == 0 {
            pill.text = "  ADD  "
            pill.backgroundColor = VelonTheme.primary
        } else {
            pill.text = "  READY  "
            pill.backgroundColor = VelonTheme.basil
        }
    }

    @objc private func addNoteTapped() {
        VelonMotion.pop(addNoteButton)
        onAddNote?()
    }

    @objc private func albumTapped() {
        VelonMotion.pop(albumButton)
        onOpenAlbum?()
    }
}
