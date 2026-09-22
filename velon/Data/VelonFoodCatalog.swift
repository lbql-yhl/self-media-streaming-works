//
//  VelonFoodCatalog.swift
//  velon
//

import Foundation

enum VelonFoodCatalog {
    static let homeCityLimit = 5
    static let homeSpotLimitPerCity = 3

    static let cities: [VelonCity] = [
        VelonCity(id: "tokyo", name: "Tokyo", country: "Japan",
                  summary: "Layered neighborhoods for ramen, izakaya, and quiet bakery counters.",
                  imageName: "1",
                  signatureTags: [.comfortBowl, .bakery, .hiddenClassic]),
        VelonCity(id: "seoul", name: "Seoul", country: "Korea",
                  summary: "Night markets, spicy stews, and alley fried chicken runs.",
                  imageName: "2",
                  signatureTags: [.spicySour, .localStreet, .comfortBowl]),
        VelonCity(id: "bangkok", name: "Bangkok", country: "Thailand",
                  summary: "Street carts, sour-hot bowls, and late river snacks.",
                  imageName: "3",
                  signatureTags: [.spicySour, .localStreet, .seafood]),
        VelonCity(id: "taipei", name: "Taipei", country: "Taiwan",
                  summary: "Night-market circuits with beef noodle and bun classics.",
                  imageName: "4",
                  signatureTags: [.localStreet, .comfortBowl, .bakery]),
        VelonCity(id: "paris", name: "Paris", country: "France",
                  summary: "Corner bakeries, wine-bar bites, and slow neighborhood meals.",
                  imageName: "5",
                  signatureTags: [.bakery, .hiddenClassic, .seafood])
    ]

    static let spots: [VelonSpot] = tokyo + seoul + bangkok + taipei + paris

    static var catalogCities: [VelonCity] { cities }

    static func catalogCity(id: String) -> VelonCity? {
        cities.first { $0.id == id }
    }

    static func city(id: String) -> VelonCity? {
        VelonCityLookup.city(id: id)
    }

    static func spot(id: String) -> VelonSpot? {
        spots.first { $0.id == id }
    }

    static func catalogSpots(inCity cityId: String) -> [VelonSpot] {
        spots.filter { $0.cityId == cityId }.sorted { $0.districtOrder < $1.districtOrder }
    }

    static func spots(inCity cityId: String) -> [VelonSpot] {
        VelonPlaceLookup.spots(inCity: cityId)
    }

    static func matchedTags(for spot: VelonSpot, preferences: Set<VelonTasteTag>) -> [VelonTasteTag] {
        spot.tags.filter { preferences.contains($0) }
    }

    static func cityMatchScore(city: VelonCity, preferences: Set<VelonTasteTag>) -> Int {
        let cityHits = city.signatureTags.filter { preferences.contains($0) }.count
        let spotHits = catalogSpots(inCity: city.id).reduce(0) { partial, spot in
            partial + matchedTags(for: spot, preferences: preferences).count
        }
        return cityHits * 2 + spotHits
    }

    static func rankedCatalogCities(preferences: Set<VelonTasteTag>) -> [VelonCity] {
        let ranked: [VelonCity]
        if preferences.isEmpty {
            ranked = cities
        } else {
            ranked = cities.sorted {
                let lhs = cityMatchScore(city: $0, preferences: preferences)
                let rhs = cityMatchScore(city: $1, preferences: preferences)
                if lhs == rhs { return $0.name < $1.name }
                return lhs > rhs
            }
        }
        return Array(ranked.prefix(homeCityLimit))
    }

    static func rankedCities(preferences: Set<VelonTasteTag>) -> [VelonCity] {
        VelonCityLookup.discoverCities(preferences: preferences)
    }

    static func rankedSpots(inCity cityId: String, preferences: Set<VelonTasteTag>) -> [VelonSpot] {
        let catalog = catalogSpots(inCity: cityId)
        let rankedCatalog: [VelonSpot]
        if preferences.isEmpty {
            rankedCatalog = catalog
        } else {
            rankedCatalog = catalog.sorted {
                let lhs = matchedTags(for: $0, preferences: preferences).count
                let rhs = matchedTags(for: $1, preferences: preferences).count
                if lhs == rhs { return $0.districtOrder < $1.districtOrder }
                return lhs > rhs
            }
        }
        let limitedCatalog = Array(rankedCatalog.prefix(homeSpotLimitPerCity))
        let custom = VelonUserStore.shared.customPlaces(inCity: cityId)
        return limitedCatalog + custom
    }

    static func optimizeStops(_ spotIds: [String]) -> [VelonRouteStop] {
        let mapped = spotIds.compactMap { id -> VelonSpot? in VelonPlaceLookup.spot(id: id) }
        let sorted = mapped.sorted { lhs, rhs in
            if lhs.districtOrder == rhs.districtOrder {
                return lhs.name < rhs.name
            }
            return lhs.districtOrder < rhs.districtOrder
        }
        var result: [VelonRouteStop] = []
        for (index, item) in sorted.enumerated() {
            let day = index < 3 ? 0 : (index < 6 ? 1 : 2)
            result.append(VelonRouteStop(spotId: item.id, dayIndex: day))
        }
        return result
    }
}

private extension VelonFoodCatalog {
    static let tokyo: [VelonSpot] = [
        make("tokyo_1", "tokyo", "Shimokitazawa Noodle Hut", "Shimokitazawa", "Rich broth bowls with a short local queue.", "1-1", [.comfortBowl, .hiddenClassic], 1, "15–30 min peak evenings", "Wed", "11:30–13:00"),
        make("tokyo_2", "tokyo", "Yanaka Butter Loaf", "Yanaka", "Quiet bakery with daily butter rolls.", "1-2", [.bakery], 2, "Often sells out by 14:00", "Mon", "09:00–11:00")
    ]

    static let seoul: [VelonSpot] = [
        make("seoul_1", "seoul", "Mangwon Market Stew", "Mangwon", "Spicy soft tofu stew near the market gate.", "2-1", [.spicySour, .comfortBowl], 1, "Shared tables at lunch", "Tue", "12:00–13:30"),
        make("seoul_2", "seoul", "Ikseon Hanok Snacks", "Ikseon", "Alley snacks inside renovated hanok lanes.", "2-2", [.localStreet, .bakery], 2, "Weekend crowd around 16:00", "None", "15:00–17:00")
    ]

    static let bangkok: [VelonSpot] = [
        make("bangkok_1", "bangkok", "Yaowarat Noodle Cart", "Yaowarat", "Sour-hot boat noodles after dusk.", "3-1", [.spicySour, .localStreet], 1, "Cash only; short stool wait", "None", "18:30–21:00"),
        make("bangkok_2", "bangkok", "Ari Grilled Prawn Stall", "Ari", "Charcoal prawns with chili lime.", "3-2", [.seafood, .spicySour], 2, "Sells out on rainy nights", "Mon", "17:00–19:30"),
        make("bangkok_3", "bangkok", "Bang Rak Curry Pot", "Bang Rak", "Thick curry over rice for midday fuel.", "3-3", [.comfortBowl, .localStreet], 3, "Busy office lunch rush", "Sun", "11:00–13:00")
    ]

    static let taipei: [VelonSpot] = [
        make("taipei_1", "taipei", "Ningxia Pepper Bun", "Ningxia", "Crisp pepper buns straight off the grill.", "4-1", [.localStreet], 1, "Evening peak after 19:00", "Mon", "18:00–20:00"),
        make("taipei_2", "taipei", "Zhongshan Beef Noodle", "Zhongshan", "Deep broth bowls with soft tendon.", "4-2", [.comfortBowl, .hiddenClassic], 2, "Shared tables; ticket order", "Tue", "11:30–13:00")
    ]

    static let paris: [VelonSpot] = [
        make("paris_1", "paris", "Canal Saint-Martin Bakery", "Canal Saint-Martin", "Butter croissants and quiet morning line.", "5-1", [.bakery], 1, "Morning queue; limited seats", "Mon", "08:00–09:30"),
        make("paris_2", "paris", "Belleville Wine Bite", "Belleville", "Small plates and neighborhood wines.", "5-2", [.hiddenClassic, .seafood], 2, "Walk-ins only after 19:00", "Sun", "18:30–20:00")
    ]

    static func make(
        _ id: String,
        _ cityId: String,
        _ name: String,
        _ district: String,
        _ blurb: String,
        _ imageName: String,
        _ tags: [VelonTasteTag],
        _ order: Int,
        _ queue: String,
        _ rest: String,
        _ window: String
    ) -> VelonSpot {
        VelonSpot(
            id: id,
            cityId: cityId,
            name: name,
            district: district,
            blurb: blurb,
            imageName: imageName,
            tags: tags,
            districtOrder: order,
            pitfall: VelonSpotPitfall(queueNote: queue, restDays: rest, bestWindow: window)
        )
    }
}
