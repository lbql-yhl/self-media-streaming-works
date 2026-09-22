//
//  VelonSpot.swift
//  velon
//

import Foundation

struct VelonSpotPitfall: Codable, Equatable {
    let queueNote: String
    let restDays: String
    let bestWindow: String
}

struct VelonSpot: Codable, Equatable {
    let id: String
    let cityId: String
    let name: String
    let district: String
    let blurb: String
    let imageName: String
    let tags: [VelonTasteTag]
    let districtOrder: Int
    let pitfall: VelonSpotPitfall

    var updatedSortKey: Int { districtOrder }
    var isCustom: Bool { id.hasPrefix("custom_") }
}
