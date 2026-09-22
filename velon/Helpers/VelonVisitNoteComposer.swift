//
//  VelonVisitNoteComposer.swift
//  velon
//

import UIKit

/// Shared flow: pick spot on a draft → write taste note → optional photo.
final class VelonVisitNoteComposer: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private weak var host: UIViewController?
    private let store = VelonUserStore.shared
    private var pendingPhotoNoteId: String?
    var onFinished: (() -> Void)?

    func start(from host: UIViewController, draft: VelonRouteDraft) {
        self.host = host
        let spots = draft.stops.compactMap { VelonPlaceLookup.spot(id: $0.spotId) }
        guard !spots.isEmpty else {
            host.velonShowAlert(title: "Empty Route", message: "Add stops to this route before writing taste notes.")
            return
        }
        let sheet = UIAlertController(title: "Add Digest Content", message: "Choose a stop for your note and photo.", preferredStyle: .actionSheet)
        sheet.view.tintColor = VelonTheme.primaryDeep
        for spot in spots {
            sheet.addAction(UIAlertAction(title: spot.name, style: .default, handler: { [weak self] _ in
                self?.composeNote(draftId: draft.id, spot: spot)
            }))
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        host.present(sheet, animated: true)
    }

    private func composeNote(draftId: String, spot: VelonSpot) {
        guard let host else { return }
        let alert = UIAlertController(title: "Taste Note", message: spot.name, preferredStyle: .alert)
        alert.view.tintColor = VelonTheme.primaryDeep
        alert.addTextField { $0.placeholder = "How did it taste?" }
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty else {
                host.velonShowAlert(title: "Missing Note", message: "Please enter a short taste note.")
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
        host.present(alert, animated: true)
        host.velonEnableTapToDismissKeyboard()
    }

    private func askPhoto(for noteId: String) {
        guard let host else { return }
        let sheet = UIAlertController(title: "Add Photo?", message: "Optional photo is kept on this device and used in Digest cards.", preferredStyle: .actionSheet)
        sheet.view.tintColor = VelonTheme.primaryDeep
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
                self?.presentPicker(noteId: noteId, source: .camera)
            }))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            sheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
                self?.presentPicker(noteId: noteId, source: .photoLibrary)
            }))
        }
        sheet.addAction(UIAlertAction(title: "Skip Photo", style: .cancel, handler: { [weak self] _ in
            self?.onFinished?()
        }))
        host.present(sheet, animated: true)
    }

    private func presentPicker(noteId: String, source: UIImagePickerController.SourceType) {
        guard let host else { return }
        pendingPhotoNoteId = noteId
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        host.present(picker, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        pendingPhotoNoteId = nil
        onFinished?()
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        defer {
            pendingPhotoNoteId = nil
            onFinished?()
        }
        guard let noteId = pendingPhotoNoteId,
              var note = store.allVisitNotes().first(where: { $0.id == noteId }),
              let image = info[.originalImage] as? UIImage,
              let data = image.jpegData(compressionQuality: 0.8),
              let path = store.saveVisitPhotoJPEG(data: data) else {
            host?.velonShowAlert(title: "Save Failed", message: "We could not save that photo. Please try again.")
            return
        }
        note.photoRelativePath = path
        store.saveVisitNote(note)
    }
}
