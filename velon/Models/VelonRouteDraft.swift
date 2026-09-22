//
//  VelonRouteDraft.swift
//  velon
//

import Foundation

struct VelonRouteStop: Codable, Equatable {
    var spotId: String
    var dayIndex: Int
}

enum VelonDraftStatus: String, Codable {
    case draft
    case selected
    case archived
}

struct VelonRouteDraft: Codable, Equatable {
    var id: String
    var title: String
    var cityId: String
    var stops: [VelonRouteStop]
    var status: VelonDraftStatus
    var updatedAt: Date

    var spotCount: Int { stops.count }

    var dayCount: Int {
        let days = Set(stops.map(\.dayIndex))
        return max(days.count, stops.isEmpty ? 0 : 1)
    }
}

struct VelonVisitNote: Codable, Equatable {
    var id: String
    var draftId: String
    var spotId: String
    var tasteNote: String
    var photoRelativePath: String?
    var createdAt: Date
}
