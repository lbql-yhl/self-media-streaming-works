//
//  VelonPlaceLookup.swift
//  velon
//

import UIKit

enum VelonPlaceLookup {
    static func spot(id: String) -> VelonSpot? {
        if let catalog = VelonFoodCatalog.spot(id: id) {
            return catalog
        }
        return VelonUserStore.shared.customPlace(id: id)
    }

    static func spots(inCity cityId: String) -> [VelonSpot] {
        let catalog = VelonFoodCatalog.catalogSpots(inCity: cityId)
        let custom = VelonUserStore.shared.customPlaces(inCity: cityId)
        return (catalog + custom).sorted { $0.districtOrder < $1.districtOrder }
    }

    static func isCustom(_ spotId: String) -> Bool {
        VelonUserStore.shared.customPlace(id: spotId) != nil
    }

    static func openDetail(spotId: String, from host: UIViewController) {
        guard let spot = spot(id: spotId) else { return }
        let page: UIViewController
        if isCustom(spotId) {
            page = VelonCustomPlaceDetailViewController(spotId: spot.id)
        } else {
            page = VelonSpotDetailViewController(spot: spot)
        }
        page.hidesBottomBarWhenPushed = true
        host.navigationController?.pushViewController(page, animated: true)
    }
}
