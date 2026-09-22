//
//  VelonVisitLogViewController.swift
//  velon
//

import UIKit

final class VelonVisitLogViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let store = VelonUserStore.shared
    private var notes: [VelonVisitNote] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyPanel = VelonUIFactory.glassPanel()
    private var pendingPhotoNoteId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Visit Notes"
        _ = velonInstallAmbient(.profile)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(addNote)
        )
        setupTable()
        setupEmpty()
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .velonUserDataDidChange, object: nil)
        reload()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        VelonMotion.staggerIn(views: [tableView], fromY: 16)
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(VelonVisitNoteCell.self, forCellReuseIdentifier: VelonVisitNoteCell.reuseId)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmpty() {
        emptyPanel.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(systemName: "square.and.pencil"))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = VelonTheme.basil
        icon.contentMode = .scaleAspectFit
        let title = VelonUIFactory.titleLabel("No taste notes yet", size: 18)
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false
        let body = VelonUIFactory.bodyLabel("After a food trip, tap + to bind a draft stop and write how it tasted. Photos stay on this device.")
        body.textAlignment = .center
        body.translatesAutoresizingMaskIntoConstraints = false
        emptyPanel.addSubview(icon)
        emptyPanel.addSubview(title)
        emptyPanel.addSubview(body)
        view.addSubview(emptyPanel)
        NSLayoutConstraint.activate([
            emptyPanel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -12),
            emptyPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            emptyPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            icon.topAnchor.constraint(equalTo: emptyPanel.topAnchor, constant: 22),
            icon.centerXAnchor.constraint(equalTo: emptyPanel.centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: 36),
            icon.heightAnchor.constraint(equalToConstant: 36),
            title.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 12),
            title.leadingAnchor.constraint(equalTo: emptyPanel.leadingAnchor, constant: 16),
            title.trailingAnchor.constraint(equalTo: emptyPanel.trailingAnchor, constant: -16),
            body.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            body.leadingAnchor.constraint(equalTo: emptyPanel.leadingAnchor, constant: 16),
            body.trailingAnchor.constraint(equalTo: emptyPanel.trailingAnchor, constant: -16),
            body.bottomAnchor.constraint(equalTo: emptyPanel.bottomAnchor, constant: -22)
        ])
    }

    @objc private func reload() {
        notes = store.allVisitNotes().sorted { $0.createdAt > $1.createdAt }
        emptyPanel.isHidden = !notes.isEmpty
        tableView.reloadData()
    }

    @objc private func addNote() {
        let drafts = store.allDrafts()
        guard !drafts.isEmpty else {
            velonShowAlert(title: "No Routes", message: "Create a route draft before adding visit notes.")
            return
        }
        let draftSheet = UIAlertController(title: "Bind to Draft", message: nil, preferredStyle: .actionSheet)
        draftSheet.view.tintColor = VelonTheme.primaryDeep
        for draft in drafts {
            draftSheet.addAction(UIAlertAction(title: draft.title, style: .default, handler: { [weak self] _ in
                self?.pickSpot(for: draft)
            }))
        }
        draftSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(draftSheet, animated: true)
    }

    private func pickSpot(for draft: VelonRouteDraft) {
        let spots = draft.stops.compactMap { VelonPlaceLookup.spot(id: $0.spotId) }
        guard !spots.isEmpty else {
            velonShowAlert(title: "Empty Draft", message: "Add spots to this draft first.")
            return
        }
        let sheet = UIAlertController(title: "Choose Spot", message: nil, preferredStyle: .actionSheet)
        sheet.view.tintColor = VelonTheme.primaryDeep
        for spot in spots {
            sheet.addAction(UIAlertAction(title: spot.name, style: .default, handler: { [weak self] _ in
                self?.composeNote(draftId: draft.id, spot: spot)
            }))
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func composeNote(draftId: String, spot: VelonSpot) {
        let alert = UIAlertController(title: "Taste Note", message: spot.name, preferredStyle: .alert)
        alert.view.tintColor = VelonTheme.primaryDeep
        alert.addTextField { field in
            field.placeholder = "How did it taste?"
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty else {
                self?.velonShowAlert(title: "Missing Note", message: "Please enter a short taste note.")
                return
            }
            let note = VelonVisitNote(
                id: UUID().uuidString,
                draftId: draftId,
                spotId: spot.id,
                tasteNote: text,
                photoRelativePath: nil,
                createdAt: Date()
            )
            self?.store.saveVisitNote(note)
            self?.askPhoto(for: note.id)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
        velonEnableTapToDismissKeyboard()
    }

    private func askPhoto(for noteId: String) {
        let sheet = UIAlertController(title: "Add Photo?", message: "Optional photo kept on this device.", preferredStyle: .actionSheet)
        sheet.view.tintColor = VelonTheme.primaryDeep
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            sheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
                self?.pendingPhotoNoteId = noteId
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.delegate = self
                self?.present(picker, animated: true)
            }))
        }
        sheet.addAction(UIAlertAction(title: "Skip", style: .cancel))
        present(sheet, animated: true)
    }

    private func addPhoto(to note: VelonVisitNote) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            velonShowAlert(title: "Unavailable", message: "Photo library is not available on this device.")
            return
        }
        pendingPhotoNoteId = note.id
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        pendingPhotoNoteId = nil
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let noteId = pendingPhotoNoteId,
              var note = store.allVisitNotes().first(where: { $0.id == noteId }),
              let image = info[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 0.8),
              let path = store.saveVisitPhotoJPEG(data: data) else {
            pendingPhotoNoteId = nil
            velonShowAlert(title: "Save Failed", message: "We could not save that photo. Please try again.")
            return
        }
        note.photoRelativePath = path
        store.saveVisitNote(note)
        pendingPhotoNoteId = nil
    }
}

extension VelonVisitLogViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { notes.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VelonVisitNoteCell.reuseId, for: indexPath) as? VelonVisitNoteCell else {
            return UITableViewCell()
        }
        let note = notes[indexPath.row]
        cell.configure(note: note)
        cell.onAddPhoto = { [weak self] in
            self?.addPhoto(to: note)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let note = notes[indexPath.row]
        var actions: [UIContextualAction] = []
        if note.photoRelativePath == nil {
            let photo = UIContextualAction(style: .normal, title: "Photo") { [weak self] _, _, done in
                self?.addPhoto(to: note)
                done(true)
            }
            photo.backgroundColor = VelonTheme.saffron
            actions.append(photo)
        }
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self else { done(false); return }
            self.store.deleteVisitNote(id: note.id)
            done(true)
        }
        actions.append(delete)
        return UISwipeActionsConfiguration(actions: actions)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 14)
        UIView.animate(withDuration: 0.36, delay: Double(indexPath.row) * 0.04, usingSpringWithDamping: 0.84, initialSpringVelocity: 0.4) {
            cell.alpha = 1
            cell.transform = .identity
        }
    }
}

final class VelonVisitNoteCell: UITableViewCell {
    static let reuseId = "VelonVisitNoteCell"
    private let card = VelonUIFactory.cardView()
    private let cover = UIImageView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let bodyLabel = UILabel()
    private let dateLabel = UILabel()
    private let photoPill = VelonUIFactory.pillLabel("PHOTO", fill: VelonTheme.basil)
    private let addPhotoButton = VelonUIFactory.secondaryButton(title: "Add Photo")
    var onAddPhoto: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        [card, cover, titleLabel, metaLabel, bodyLabel, dateLabel, photoPill, addPhotoButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        cover.contentMode = .scaleAspectFill
        cover.clipsToBounds = true
        cover.layer.cornerRadius = 16
        cover.backgroundColor = VelonTheme.separator

        titleLabel.font = .systemFont(ofSize: 17, weight: .heavy)
        titleLabel.textColor = VelonTheme.charcoal
        metaLabel.font = .systemFont(ofSize: 12, weight: .bold)
        metaLabel.textColor = VelonTheme.warmStone
        metaLabel.numberOfLines = 1
        bodyLabel.font = .systemFont(ofSize: 14, weight: .medium)
        bodyLabel.textColor = VelonTheme.deepAccent
        bodyLabel.numberOfLines = 3
        dateLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        dateLabel.textColor = VelonTheme.warmStone
        addPhotoButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)

        contentView.addSubview(card)
        [cover, titleLabel, metaLabel, bodyLabel, dateLabel, photoPill, addPhotoButton].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            cover.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            cover.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            cover.widthAnchor.constraint(equalToConstant: 84),
            cover.heightAnchor.constraint(equalToConstant: 84),

            photoPill.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            photoPill.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            photoPill.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.topAnchor.constraint(equalTo: cover.topAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: cover.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: photoPill.leadingAnchor, constant: -8),

            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            bodyLabel.topAnchor.constraint(equalTo: metaLabel.bottomAnchor, constant: 6),
            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            dateLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: addPhotoButton.leadingAnchor, constant: -8),
            dateLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -14),

            addPhotoButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            addPhotoButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            addPhotoButton.heightAnchor.constraint(equalToConstant: 36),
            addPhotoButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 96),

            cover.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func configure(note: VelonVisitNote) {
        let spot = VelonPlaceLookup.spot(id: note.spotId)
        let draft = VelonUserStore.shared.allDrafts().first(where: { $0.id == note.draftId })
        let city = draft.flatMap { VelonCityLookup.city(id: $0.cityId) }

        titleLabel.text = spot?.name ?? "Stop"
        metaLabel.text = [city?.name, spot?.district, draft?.title]
            .compactMap { $0 }
            .joined(separator: " · ")
        bodyLabel.text = note.tasteNote
        dateLabel.text = VelonVisitNoteCell.dateFormatter.string(from: note.createdAt)

        if let relative = note.photoRelativePath,
           let url = VelonUserStore.shared.documentsRelativeURL(path: relative),
           let image = UIImage(contentsOfFile: url.path) {
            cover.image = image
            photoPill.isHidden = false
            photoPill.text = "  PHOTO  "
            photoPill.backgroundColor = VelonTheme.basil
            addPhotoButton.isHidden = true
        } else {
            if let spot {
                VelonImageLoader.apply(to: cover, named: spot.imageName, cornerRadius: 16)
            } else if let city {
                VelonImageLoader.apply(to: cover, city: city, cornerRadius: 16)
            } else {
                cover.image = UIImage(systemName: "fork.knife")
                cover.tintColor = VelonTheme.warmStone
                cover.contentMode = .center
            }
            photoPill.isHidden = false
            photoPill.text = "  NO PHOTO  "
            photoPill.backgroundColor = VelonTheme.warmStone
            addPhotoButton.isHidden = false
        }
    }

    @objc private func addPhotoTapped() {
        VelonMotion.pop(addPhotoButton)
        onAddPhoto?()
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
