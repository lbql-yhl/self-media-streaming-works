//
//  VelonCityLookup.swift
//  velon
//

import Foundation

enum VelonCityLookup {
    static func city(id: String) -> VelonCity? {
        if let catalog = VelonFoodCatalog.catalogCity(id: id) {
            return catalog
        }
        return VelonUserStore.shared.customCity(id: id)
    }

    static func allCities() -> [VelonCity] {
        VelonFoodCatalog.catalogCities + VelonUserStore.shared.allCustomCities()
    }

    /// Home Discover list: top ranked catalog cities + all custom cities.
    static func discoverCities(preferences: Set<VelonTasteTag>) -> [VelonCity] {
        let rankedCatalog = VelonFoodCatalog.rankedCatalogCities(preferences: preferences)
        let custom = VelonUserStore.shared.allCustomCities()
        return rankedCatalog + custom
    }
}
