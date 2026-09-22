//
//  VelonCustomCityComposerViewController.swift
//  velon
//

import UIKit

final class VelonCustomCityComposerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let store = VelonUserStore.shared
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let nameField = UITextField()
    private let countryField = UITextField()
    private let summaryField = UITextView()
    private let coverImageView = UIImageView()
    private let pickCoverButton = VelonUIFactory.secondaryButton(title: "Upload Cover Photo")
    private var selectedTags = Set<VelonTasteTag>([.localStreet])
    private let tagStack = UIStackView()
    private var coverJPEGData: Data?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Custom City"
        _ = velonInstallAmbient(.discover)
        velonEnableTapToDismissKeyboard()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        styleField(nameField, placeholder: "City name")
        styleField(countryField, placeholder: "Country / region")
        summaryField.font = .systemFont(ofSize: 15, weight: .medium)
        summaryField.textColor = VelonTheme.charcoal
        summaryField.backgroundColor = UIColor.white.withAlphaComponent(0.88)
        summaryField.layer.cornerRadius = 14
        summaryField.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        summaryField.heightAnchor.constraint(equalToConstant: 110).isActive = true

        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = 18
        coverImageView.backgroundColor = VelonTheme.separator
        coverImageView.image = UIImage(systemName: "photo.on.rectangle.angled")
        coverImageView.tintColor = VelonTheme.warmStone
        coverImageView.contentMode = .center

        pickCoverButton.addTarget(self, action: #selector(pickCover), for: .touchUpInside)

        tagStack.axis = .vertical
        tagStack.spacing = 8
        rebuildTags()

        [
            section("Cover photo"),
            coverImageView,
            pickCoverButton,
            section("Basics"),
            nameField,
            countryField,
            summaryField,
            section("Signature tastes"),
            tagStack
        ].forEach { stack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -28),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }

    private func section(_ text: String) -> UILabel {
        VelonUIFactory.titleLabel(text, size: 16)
    }

    private func styleField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.borderStyle = .none
        field.backgroundColor = UIColor.white.withAlphaComponent(0.88)
        field.layer.cornerRadius = 14
        field.font = .systemFont(ofSize: 15, weight: .semibold)
        field.textColor = VelonTheme.charcoal
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        field.leftViewMode = .always
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    private func rebuildTags() {
        tagStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        var row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        for (index, tag) in VelonTasteTag.allCases.enumerated() {
            if index > 0 && index % 2 == 0 {
                tagStack.addArrangedSubview(row)
                row = UIStackView()
                row.axis = .horizontal
                row.spacing = 8
                row.distribution = .fillEqually
            }
            let button = UIButton(type: .system)
            button.setTitle(tag.displayName, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
            button.layer.cornerRadius = 14
            button.heightAnchor.constraint(equalToConstant: 40).isActive = true
            let on = selectedTags.contains(tag)
            button.backgroundColor = on ? VelonTheme.primary : UIColor.white.withAlphaComponent(0.88)
            button.setTitleColor(on ? .white : VelonTheme.deepAccent, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(toggleTag(_:)), for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        tagStack.addArrangedSubview(row)
    }

    @objc private func toggleTag(_ sender: UIButton) {
        let tag = VelonTasteTag.allCases[sender.tag]
        if selectedTags.contains(tag) { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
        rebuildTags()
    }

    @objc private func pickCover() {
        let sheet = UIAlertController(title: "Cover Photo", message: nil, preferredStyle: .actionSheet)
        sheet.view.tintColor = VelonTheme.primaryDeep
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
                self?.presentImagePicker(source: .camera)
            }))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            sheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
                self?.presentImagePicker(source: .photoLibrary)
            }))
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func presentImagePicker(source: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        guard let image else {
            velonShowAlert(title: "Import Failed", message: "We could not read that photo. Please try again.")
            return
        }
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.image = image
        coverJPEGData = image.jpegData(compressionQuality: 0.85)
        pickCoverButton.setTitle("Change Cover Photo", for: .normal)
        VelonMotion.pop(coverImageView)
    }

    @objc private func saveTapped() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            velonShowAlert(title: "Missing Name", message: "Please enter a city name.")
            return
        }
        let city = store.makeCustomCity(
            name: name,
            country: countryField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            summary: summaryField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            tags: Array(selectedTags),
            coverJPEGData: coverJPEGData
        )
        let detail = VelonCityDetailViewController(city: city)
        detail.hidesBottomBarWhenPushed = true
        if let nav = navigationController {
            var stack = nav.viewControllers
            stack.removeLast()
            stack.append(detail)
            nav.setViewControllers(stack, animated: true)
        }
    }
}
