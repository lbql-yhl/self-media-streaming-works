//
//  VelonCustomPlaceComposerViewController.swift
//  velon
//

import UIKit

final class VelonCustomPlaceComposerViewController: UIViewController {
    private let store = VelonUserStore.shared
    private let cities = VelonCityLookup.allCities()
    private var selectedCityId: String
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let nameField = UITextField()
    private let districtField = UITextField()
    private let blurbField = UITextView()
    private let queueField = UITextField()
    private let restField = UITextField()
    private let windowField = UITextField()
    private let cityButton = VelonUIFactory.secondaryButton(title: "Choose City")
    private var selectedTags = Set<VelonTasteTag>([.localStreet])
    private let tagStack = UIStackView()
    var onSaved: ((VelonSpot) -> Void)?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        selectedCityId = cities.first?.id ?? "tokyo"
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        selectedCityId = "tokyo"
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Custom Place"
        _ = velonInstallAmbient(.routes)
        velonEnableTapToDismissKeyboard()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        refreshCityButton()
        cityButton.addTarget(self, action: #selector(pickCity), for: .touchUpInside)
        styleField(nameField, placeholder: "Place name")
        styleField(districtField, placeholder: "District / area")
        styleField(queueField, placeholder: "Queue tip")
        styleField(restField, placeholder: "Rest days")
        styleField(windowField, placeholder: "Best time window")
        blurbField.font = .systemFont(ofSize: 15, weight: .medium)
        blurbField.textColor = VelonTheme.charcoal
        blurbField.backgroundColor = UIColor.white.withAlphaComponent(0.88)
        blurbField.layer.cornerRadius = 14
        blurbField.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        blurbField.heightAnchor.constraint(equalToConstant: 96).isActive = true

        tagStack.axis = .vertical
        tagStack.spacing = 8
        rebuildTags()

        [
            sectionTitle("City"),
            cityButton,
            sectionTitle("Basics"),
            nameField,
            districtField,
            blurbField,
            sectionTitle("Taste tags"),
            tagStack,
            sectionTitle("Pitfall notes"),
            queueField,
            restField,
            windowField
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

    private func sectionTitle(_ text: String) -> UILabel {
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

    private func refreshCityButton() {
        guard let city = VelonCityLookup.city(id: selectedCityId) else {
            cityButton.setTitle("Choose City", for: .normal)
            return
        }
        let label = city.isCustom ? "\(city.name) (Custom)" : city.name
        cityButton.setTitle(label, for: .normal)
    }

    @objc private func pickCity() {
        let sheet = UIAlertController(title: "Choose City", message: nil, preferredStyle: .actionSheet)
        sheet.view.tintColor = VelonTheme.primaryDeep
        for city in cities {
            let title = city.isCustom ? "\(city.name) (Custom)" : city.name
            sheet.addAction(UIAlertAction(title: title, style: .default, handler: { [weak self] _ in
                self?.selectedCityId = city.id
                self?.refreshCityButton()
            }))
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func rebuildTags() {
        tagStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        var current = UIStackView()
        current.axis = .horizontal
        current.spacing = 8
        current.distribution = .fillEqually
        for (index, tag) in VelonTasteTag.allCases.enumerated() {
            if index > 0 && index % 2 == 0 {
                tagStack.addArrangedSubview(current)
                current = UIStackView()
                current.axis = .horizontal
                current.spacing = 8
                current.distribution = .fillEqually
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
            current.addArrangedSubview(button)
        }
        tagStack.addArrangedSubview(current)
    }

    @objc private func toggleTag(_ sender: UIButton) {
        let tag = VelonTasteTag.allCases[sender.tag]
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        rebuildTags()
    }

    @objc private func saveTapped() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            velonShowAlert(title: "Missing Name", message: "Please enter a place name.")
            return
        }
        let place = store.makeCustomPlace(
            cityId: selectedCityId,
            name: name,
            district: districtField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            blurb: blurbField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            tags: Array(selectedTags),
            queueNote: queueField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            restDays: restField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            bestWindow: windowField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        )
        onSaved?(place)
        if let nav = navigationController, nav.viewControllers.count > 1 {
            let detail = VelonCustomPlaceDetailViewController(spotId: place.id)
            detail.hidesBottomBarWhenPushed = true
            var stack = nav.viewControllers
            stack.removeLast()
            stack.append(detail)
            nav.setViewControllers(stack, animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
