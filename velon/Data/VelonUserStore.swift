//
//  VelonUserStore.swift
//  velon
//

import Foundation

final class VelonUserStore {
    static let shared = VelonUserStore()

    private let defaults = UserDefaults.standard
    private let preferencesKey = "velon.preferences"
    private let wishlistKey = "velon.wishlist"
    private let draftsKey = "velon.drafts"
    private let visitsKey = "velon.visits"
    private let coinsKey = "velon.coins"
    private let customPlacesKey = "velon.customPlaces"
    private let customCitiesKey = "velon.customCities"
    private let fileManager = FileManager.default

    private init() {
        if defaults.object(forKey: coinsKey) == nil {
            defaults.set(VelonCoinEconomy.startingBalance, forKey: coinsKey)
        }
    }

    var tastePreferences: Set<VelonTasteTag> {
        get {
            guard let raw = defaults.array(forKey: preferencesKey) as? [String] else { return [] }
            return Set(raw.compactMap { VelonTasteTag(rawValue: $0) })
        }
        set {
            defaults.set(newValue.map(\.rawValue).sorted(), forKey: preferencesKey)
            NotificationCenter.default.post(name: .velonUserDataDidChange, object: nil)
        }
    }

    var wishlistSpotIds: [String] {
        get { defaults.stringArray(forKey: wishlistKey) ?? [] }
        set {
            defaults.set(newValue, forKey: wishlistKey)
            NotificationCenter.default.post(name: .velonUserDataDidChange, object: nil)
        }
    }

    var coinBalance: Int {
        get { defaults.integer(forKey: coinsKey) }
        set {
            defaults.set(max(0, newValue), forKey: coinsKey)
            NotificationCenter.default.post(name: .velonUserDataDidChange, object: nil)
        }
    }

    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard amount > 0, coinBalance >= amount else { return false }
        coinBalance -= amount
        return true
    }

    func isWishlisted(_ spotId: String) -> Bool {
        wishlistSpotIds.contains(spotId)
    }

    func toggleWishlist(_ spotId: String) {
        var list = wishlistSpotIds
        if let index = list.firstIndex(of: spotId) {
            list.remove(at: index)
        } else {
            list.insert(spotId, at: 0)
        }
        wishlistSpotIds = list
    }

    func allDrafts() -> [VelonRouteDraft] {
        decode([VelonRouteDraft].self, key: draftsKey) ?? []
    }

    func drafts(forCity cityId: String) -> [VelonRouteDraft] {
        allDrafts()
            .filter { $0.cityId == cityId }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func draft(id: String) -> VelonRouteDraft? {
        allDrafts().first { $0.id == id }
    }

    func saveDraft(_ draft: VelonRouteDraft) {
        var list = allDrafts()
        if let index = list.firstIndex(where: { $0.id == draft.id }) {
            list[index] = draft
        } else {
            list.insert(draft, at: 0)
        }
        encode(list, key: draftsKey)
        NotificationCenter.default.post(name: .velonUserDataDidChange, object: nil)
    }

    func deleteDraft(id: String) {
        var list = allDrafts().filter { $0.id != id }
        encode(list, key: draftsKey)
        NotificationCenter.default.post(name: .velonUserDataDidChange, object: nil)
    }

    func selectDraft(id: String) {
        var list = allDrafts()
        guard let target = list.first(where: { $0.id == id }) else { return }
        for index in list.indices {
            if list[index].cityId == target.cityId {
                if list[index].id == id {
                    list[index].status = .selected
                } else if list[index].status == .selected {
                    list[index].status = .archived
                }
            }
        }
        encode(list, key: draftsKey)
        NotificationCenter.default.post(name: .velonUserDataDidChange, object: nil)
    }

    func createDraft(cityId: String, title: String, spotIds: [String]) -> VelonRouteDraft {
        let draft = VelonRouteDraft(
            id: UUID().uuidString,
            title: title,
            cityId: cityId,
            stops: VelonFoodCatalog.optimizeStops(spotIds),
            status: .draft,
            updatedAt: Date()
        )
        saveDraft(draft)
        return draft
    }

    func allCustomPlaces() -> [VelonSpot] {
        decode([VelonSpot].self, key: customPlacesKey) ?? []
    }

    func customPlaces(inCity cityId: String) -> [VelonSpot] {
        allCustomPlaces()
            .filter { $0.cityId == cityId }
            .sorted { $0.updatedSortKey > $1.updatedSortKey }
    }

    func customPlace(id: String) -> VelonSpot? {
        allCustomPlaces().first { $0.id == id }
    }

    func saveCustomPlace(_ place: VelonSpot) {
        var list = allCustomPlaces()
        if let index = list.firstIndex(where: { $0.id == place.id }) {
            list[index] = place
        } else {
            list.insert(place, at: 0)
        }
        encode(list, key: customPlacesKey)
        NotificationCenter.default.post(name: .velonUserDataDidChange, object: nil)
    }

    func deleteCustomPlace(id: String) {
        var list = allCustomPlaces().filter { $0.id != id }
        encode(list, key: customPlacesKey)
        wishlistSpotIds = wishlistSpotIds.filter { $0 != id }
        var drafts = allDrafts()
        for index in drafts.indices {
            drafts[index].stops.removeAll { $0.spotId == id }
            drafts[index].updatedAt = Date()
        }
        encode(drafts, key: draftsKey)
        NotificationCenter.default.post(name: .velonUserDataDidChange, object: nil)
    }

    func makeCustomPlace(
        cityId: String,
        name: String,
        district: String,
        blurb: String,
        tags: [VelonTasteTag],
        queueNote: String,
        restDays: String,
        bestWindow: String
    ) -> VelonSpot {
        let cityImage = VelonCityLookup.city(id: cityId)?.imageName ?? "1"
        let existingCount = customPlaces(inCity: cityId).count
        let place = VelonSpot(
            id: "custom_\(UUID().uuidString)",
            cityId: cityId,
            name: name,
            district: district.isEmpty ? "Custom" : district,
            blurb: blurb.isEmpty ? "Your custom tasting stop." : blurb,
            imageName: cityImage,
            tags: tags.isEmpty ? [.localStreet] : tags,
            districtOrder: 100 + existingCount,
            pitfall: VelonSpotPitfall(
                queueNote: queueNote.isEmpty ? "Add your own queue tip" : queueNote,
                restDays: restDays.isEmpty ? "Unknown" : restDays,
                bestWindow: bestWindow.isEmpty ? "Anytime" : bestWindow
            )
        )
        saveCustomPlace(place)
        return place
    }

    func allCustomCities() -> [VelonCity] {
        decode([VelonCity].self, key: customCitiesKey) ?? []
    }

    func customCity(id: String) -> VelonCity? {
        allCustomCities().first { $0.id == id }
    }

    func saveCustomCity(_ city: VelonCity) {
        var list = allCustomCities()
        if let index = list.firstIndex(where: { $0.id == city.id }) {
            list[index] = city
        } else {
            list.insert(city, at: 0)
        }
        encode(list, key: customCitiesKey)
        NotificationCenter.default.post(name: .velonUserDataDidChange, object: nil)
    }

    func deleteCustomCity(id: String) {
        var list = allCustomCities().filter { $0.id != id }
        encode(list, key: customCitiesKey)
        NotificationCenter.default.post(name: .velonUserDataDidChange, object: nil)
    }

    func makeCustomCity(
        name: String,
        country: String,
        summary: String,
        tags: [VelonTasteTag],
        coverJPEGData: Data?
    ) -> VelonCity {
        let covers = ["1", "2", "3", "4", "5"]
        let fallback = covers[allCustomCities().count % covers.count]
        let uploadedPath = coverJPEGData.flatMap { saveCityCoverJPEG(data: $0) }
        let city = VelonCity(
            id: "customcity_\(UUID().uuidString)",
            name: name,
            country: country.isEmpty ? "Custom" : country,
            summary: summary.isEmpty ? "Your custom food destination for planning tasting routes." : summary,
            imageName: fallback,
            signatureTags: tags.isEmpty ? [.localStreet] : tags,
            coverRelativePath: uploadedPath
        )
        saveCustomCity(city)
        return city
    }

    func saveCityCoverJPEG(data: Data) -> String? {
        guard let root = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = root.appendingPathComponent("velon_cities", isDirectory: true)
        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            let name = "\(UUID().uuidString).jpg"
            let url = folder.appendingPathComponent(name)
            try data.write(to: url, options: .atomic)
            return "velon_cities/\(name)"
        } catch {
            return nil
        }
    }

    func allVisitNotes() -> [VelonVisitNote] {
        decode([VelonVisitNote].self, key: visitsKey) ?? []
    }

    func visitNotes(forDraftId draftId: String) -> [VelonVisitNote] {
        allVisitNotes()
            .filter { $0.draftId == draftId }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func saveVisitNote(_ note: VelonVisitNote) {
        var list = allVisitNotes()
        if let index = list.firstIndex(where: { $0.id == note.id }) {
            list[index] = note
        } else {
            list.insert(note, at: 0)
        }
        encode(list, key: visitsKey)
        NotificationCenter.default.post(name: .velonUserDataDidChange, object: nil)
    }

    func deleteVisitNote(id: String) {
        var list = allVisitNotes().filter { $0.id != id }
        encode(list, key: visitsKey)
        NotificationCenter.default.post(name: .velonUserDataDidChange, object: nil)
    }

    func documentsRelativeURL(path: String) -> URL? {
        guard let root = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return root.appendingPathComponent(path)
    }

    func saveVisitPhotoJPEG(data: Data) -> String? {
        guard let root = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = root.appendingPathComponent("velon_visits", isDirectory: true)
        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            let name = "\(UUID().uuidString).jpg"
            let url = folder.appendingPathComponent(name)
            try data.write(to: url, options: .atomic)
            return "velon_visits/\(name)"
        } catch {
            return nil
        }
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }
}

extension Notification.Name {
    static let velonUserDataDidChange = Notification.Name("velonUserDataDidChange")
}
