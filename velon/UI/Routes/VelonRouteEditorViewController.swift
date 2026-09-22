//
//  VelonRouteEditorViewController.swift
//  velon
//

import UIKit

final class VelonRouteEditorViewController: UIViewController {
    private let draftId: String
    private let store = VelonUserStore.shared
    private var draft: VelonRouteDraft?
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let optimizeButton = VelonUIFactory.secondaryButton(title: "Optimize by District")
    private let addSpotButton = VelonUIFactory.secondaryButton(title: "Add Spot")
    private let selectButton = VelonUIFactory.primaryButton(title: "Mark as Selected Plan")
    private let headerCard = VelonUIFactory.glassPanel()
    private let headerMeta = UILabel()

    init(draftId: String) {
        self.draftId = draftId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        _ = velonInstallAmbient(.routes)
        setupHeader()
        setupTable()
        setupButtons()
        reload()
        VelonMotion.staggerIn(views: [headerCard, tableView, optimizeButton, addSpotButton, selectButton], fromY: 22)
    }

    private func setupHeader() {
        headerCard.translatesAutoresizingMaskIntoConstraints = false
        headerMeta.translatesAutoresizingMaskIntoConstraints = false
        headerMeta.font = .systemFont(ofSize: 14, weight: .semibold)
        headerMeta.textColor = VelonTheme.warmStone
        headerMeta.numberOfLines = 0
        let tip = VelonUIFactory.pillLabel("DRAG TO REORDER", fill: VelonTheme.saffron)
        tip.translatesAutoresizingMaskIntoConstraints = false
        headerCard.addSubview(headerMeta)
        headerCard.addSubview(tip)
        view.addSubview(headerCard)
        NSLayoutConstraint.activate([
            headerCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tip.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 14),
            tip.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 14),
            tip.heightAnchor.constraint(equalToConstant: 22),
            headerMeta.topAnchor.constraint(equalTo: tip.bottomAnchor, constant: 8),
            headerMeta.leadingAnchor.constraint(equalTo: tip.leadingAnchor),
            headerMeta.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -14),
            headerMeta.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -14)
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isEditing = true
        tableView.allowsSelectionDuringEditing = true
        tableView.backgroundColor = .clear
        view.addSubview(tableView)
    }

    private func setupButtons() {
        let buttonStack = UIStackView(arrangedSubviews: [optimizeButton, addSpotButton, selectButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 8
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)

        optimizeButton.addTarget(self, action: #selector(optimize), for: .touchUpInside)
        addSpotButton.addTarget(self, action: #selector(addSpot), for: .touchUpInside)
        selectButton.addTarget(self, action: #selector(markSelected), for: .touchUpInside)

        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            tableView.topAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -8)
        ])
    }

    private func reload() {
        draft = store.draft(id: draftId)
        title = draft?.title ?? "Route"
        let city = VelonFoodCatalog.city(id: draft?.cityId ?? "")?.name ?? ""
        headerMeta.text = "\(city) tasting path · \(draft?.spotCount ?? 0) stops across \(draft?.dayCount ?? 0) day(s). Tap a stop to move days or open the spot."
        tableView.reloadData()
    }

    private func persist(_ updated: VelonRouteDraft) {
        var copy = updated
        copy.updatedAt = Date()
        store.saveDraft(copy)
        draft = copy
        reload()
    }

    @objc private func optimize() {
        guard var draft else { return }
        VelonMotion.pop(optimizeButton)
        let ids = draft.stops.map(\.spotId)
        draft.stops = VelonFoodCatalog.optimizeStops(ids)
        persist(draft)
        velonShowAlert(title: "Optimized", message: "Stops were reordered by district to reduce backtracking.")
    }

    @objc private func addSpot() {
        guard let draft else { return }
        let existing = Set(draft.stops.map(\.spotId))
        let candidates = VelonPlaceLookup.spots(inCity: draft.cityId).filter { !existing.contains($0.id) }
        guard !candidates.isEmpty else {
            velonShowAlert(title: "All Added", message: "Every spot in this city is already on the draft.")
            return
        }
        let sheet = UIAlertController(title: "Add Spot", message: nil, preferredStyle: .actionSheet)
        sheet.view.tintColor = VelonTheme.primaryDeep
        for spot in candidates {
            let prefix = spot.isCustom ? "[Custom] " : ""
            sheet.addAction(UIAlertAction(title: "\(prefix)\(spot.district): \(spot.name)", style: .default, handler: { [weak self] _ in
                guard var current = self?.draft else { return }
                let day = current.stops.map(\.dayIndex).max() ?? 0
                current.stops.append(VelonRouteStop(spotId: spot.id, dayIndex: day))
                self?.persist(current)
            }))
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    @objc private func markSelected() {
        VelonMotion.pop(selectButton)
        store.selectDraft(id: draftId)
        reload()
        velonShowAlert(title: "Selected", message: "This draft is now your selected plan for the city. Others were archived.")
    }
}

extension VelonRouteEditorViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        let maxDay = draft?.stops.map(\.dayIndex).max() ?? 0
        return (draft?.stops.isEmpty == false) ? maxDay + 1 : 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Day \(section + 1)"
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = .systemFont(ofSize: 14, weight: .heavy)
        header.textLabel?.textColor = VelonTheme.deepAccent
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        draft?.stops.filter { $0.dayIndex == section }.count ?? 0
    }

    private func stop(at indexPath: IndexPath) -> VelonRouteStop? {
        guard let draft else { return nil }
        let filtered = draft.stops.filter { $0.dayIndex == indexPath.section }
        guard indexPath.row < filtered.count else { return nil }
        return filtered[indexPath.row]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stop") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "stop")
        guard let stop = stop(at: indexPath), let spot = VelonPlaceLookup.spot(id: stop.spotId) else { return cell }
        cell.textLabel?.text = spot.isCustom ? "\(spot.name) · Custom" : spot.name
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .heavy)
        cell.textLabel?.textColor = VelonTheme.charcoal
        cell.detailTextLabel?.numberOfLines = 2
        cell.detailTextLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        cell.detailTextLabel?.textColor = VelonTheme.warmStone
        cell.detailTextLabel?.text = "\(spot.district) · Queue: \(spot.pitfall.queueNote)"
        cell.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        cell.layer.cornerRadius = 12
        return cell
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { true }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard var draft else { return }
        var working = draft.stops
        let sourceStops = working.enumerated().filter { $0.element.dayIndex == sourceIndexPath.section }
        guard sourceIndexPath.row < sourceStops.count else { return }
        let moved = sourceStops[sourceIndexPath.row]
        working.remove(at: moved.offset)
        var inserted = moved.element
        inserted.dayIndex = destinationIndexPath.section
        let destOffsets = working.enumerated().filter { $0.element.dayIndex == destinationIndexPath.section }
        if destinationIndexPath.row >= destOffsets.count {
            if let last = destOffsets.last {
                working.insert(inserted, at: last.offset + 1)
            } else {
                working.append(inserted)
            }
        } else {
            working.insert(inserted, at: destOffsets[destinationIndexPath.row].offset)
        }
        draft.stops = working
        persist(draft)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, var draft, let stop = stop(at: indexPath) else { return }
        draft.stops.removeAll { $0.spotId == stop.spotId && $0.dayIndex == stop.dayIndex }
        persist(draft)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let stop = stop(at: indexPath) else { return }
        let sheet = UIAlertController(title: "Move to Day", message: nil, preferredStyle: .actionSheet)
        sheet.view.tintColor = VelonTheme.primaryDeep
        for day in 0..<3 {
            sheet.addAction(UIAlertAction(title: "Day \(day + 1)", style: .default, handler: { [weak self] _ in
                guard var draft = self?.draft else { return }
                if let idx = draft.stops.firstIndex(where: { $0.spotId == stop.spotId && $0.dayIndex == stop.dayIndex }) {
                    draft.stops[idx].dayIndex = day
                    self?.persist(draft)
                }
            }))
        }
        sheet.addAction(UIAlertAction(title: "Open Detail", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            VelonPlaceLookup.openDetail(spotId: stop.spotId, from: self)
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
}
