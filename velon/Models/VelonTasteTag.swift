//
//  VelonTasteTag.swift
//  velon
//

import Foundation

enum VelonTasteTag: String, Codable, CaseIterable {
    case spicySour
    case bakery
    case localStreet
    case hiddenClassic
    case seafood
    case comfortBowl

    var displayName: String {
        switch self {
        case .spicySour: return "Spicy & Sour"
        case .bakery: return "Bakery"
        case .localStreet: return "Local Street"
        case .hiddenClassic: return "Hidden Classic"
        case .seafood: return "Seafood"
        case .comfortBowl: return "Comfort Bowl"
        }
    }
}
