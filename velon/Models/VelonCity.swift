//
//  VelonCity.swift
//  velon
//

import Foundation

struct VelonCity: Codable, Equatable {
    let id: String
    let name: String
    let country: String
    let summary: String
    let imageName: String
    let signatureTags: [VelonTasteTag]
    /// Relative Documents path for user-uploaded cover. Nil for catalog cities.
    let coverRelativePath: String?

    var isCustom: Bool { id.hasPrefix("customcity_") }

    init(
        id: String,
        name: String,
        country: String,
        summary: String,
        imageName: String,
        signatureTags: [VelonTasteTag],
        coverRelativePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.summary = summary
        self.imageName = imageName
        self.signatureTags = signatureTags
        self.coverRelativePath = coverRelativePath
    }
}
