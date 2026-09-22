//
//  VelonDigestCardRenderer.swift
//  velon
//

import UIKit

enum VelonDigestCardRenderer {
    static let cardSize = CGSize(width: 1080, height: 1440)

    static func albumImages(draft: VelonRouteDraft, notes: [VelonVisitNote]) -> [UIImage] {
        let cityName = VelonCityLookup.city(id: draft.cityId)?.name ?? draft.cityId
        var images = [coverImage(draft: draft, noteCount: notes.count)]
        for note in notes {
            let spot = VelonPlaceLookup.spot(id: note.spotId)
            images.append(noteCard(note: note, spot: spot, cityName: cityName))
        }
        return images
    }

    static func coverImage(draft: VelonRouteDraft, noteCount: Int) -> UIImage {
        let city = VelonCityLookup.city(id: draft.cityId)
        let coverAsset = city.flatMap { VelonImageLoader.image(forCity: $0) }
        return render(size: cardSize) { bounds in
            let colors = [VelonTheme.deepAccent.cgColor, VelonTheme.primaryDeep.cgColor, VelonTheme.primary.cgColor]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 0.55, 1]) {
                UIGraphicsGetCurrentContext()?.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: bounds.maxX, y: bounds.maxY),
                    options: []
                )
            }

            if let coverAsset {
                let rect = CGRect(x: 72, y: 160, width: bounds.width - 144, height: 520)
                UIGraphicsGetCurrentContext()?.saveGState()
                UIBezierPath(roundedRect: rect, cornerRadius: 48).addClip()
                coverAsset.draw(in: rect)
                UIGraphicsGetCurrentContext()?.restoreGState()
            }

            drawText("POST-TRIP DIGEST", font: .systemFont(ofSize: 36, weight: .heavy), color: VelonTheme.saffron, in: CGRect(x: 80, y: 720, width: bounds.width - 160, height: 50))
            drawText(city?.name ?? "Food City", font: .systemFont(ofSize: 92, weight: .black), color: .white, in: CGRect(x: 80, y: 780, width: bounds.width - 160, height: 110))
            drawText(draft.title, font: .systemFont(ofSize: 42, weight: .bold), color: UIColor.white.withAlphaComponent(0.9), in: CGRect(x: 80, y: 900, width: bounds.width - 160, height: 60))
            drawText("\(draft.spotCount) stops  ·  \(noteCount) taste notes", font: .systemFont(ofSize: 34, weight: .semibold), color: UIColor.white.withAlphaComponent(0.8), in: CGRect(x: 80, y: 980, width: bounds.width - 160, height: 50))
            drawText("Velon", font: .systemFont(ofSize: 28, weight: .heavy), color: UIColor.white.withAlphaComponent(0.7), in: CGRect(x: 80, y: 1320, width: bounds.width - 160, height: 40))
        }
    }

    private static func noteCard(note: VelonVisitNote, spot: VelonSpot?, cityName: String) -> UIImage {
        let photo = loadPhoto(note.photoRelativePath)
        let cover = spot.flatMap { VelonImageLoader.image(named: $0.imageName) }
        return render(size: cardSize) { bounds in
            UIColor(red: 1, green: 0.96, blue: 0.93, alpha: 1).setFill()
            UIBezierPath(rect: bounds).fill()

            let heroRect = CGRect(x: 64, y: 96, width: bounds.width - 128, height: 620)
            UIGraphicsGetCurrentContext()?.saveGState()
            UIBezierPath(roundedRect: heroRect, cornerRadius: 44).addClip()
            if let image = photo ?? cover {
                image.draw(in: heroRect)
            } else {
                VelonTheme.primary.setFill()
                UIBezierPath(rect: heroRect).fill()
            }
            UIGraphicsGetCurrentContext()?.restoreGState()

            drawText("TASTE NOTE", font: .systemFont(ofSize: 28, weight: .heavy), color: VelonTheme.saffron, in: CGRect(x: 80, y: 760, width: bounds.width - 160, height: 40))
            drawText(spot?.name ?? "Custom stop", font: .systemFont(ofSize: 56, weight: .black), color: VelonTheme.charcoal, in: CGRect(x: 80, y: 820, width: bounds.width - 160, height: 80))
            drawText("\(cityName)  ·  \(spot?.district ?? "Local")", font: .systemFont(ofSize: 30, weight: .semibold), color: VelonTheme.warmStone, in: CGRect(x: 80, y: 910, width: bounds.width - 160, height: 40))
            drawText(note.tasteNote, font: .systemFont(ofSize: 36, weight: .medium), color: VelonTheme.deepAccent, in: CGRect(x: 80, y: 980, width: bounds.width - 160, height: 260))
            drawText("Velon Digest", font: .systemFont(ofSize: 26, weight: .heavy), color: VelonTheme.primaryDeep, in: CGRect(x: 80, y: 1320, width: bounds.width - 160, height: 36))
        }
    }

    private static func loadPhoto(_ relativePath: String?) -> UIImage? {
        guard let relativePath,
              let url = VelonUserStore.shared.documentsRelativeURL(path: relativePath) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }

    private static func render(size: CGSize, draw: (CGRect) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(CGRect(origin: .zero, size: size))
        }
    }

    private static func drawText(_ text: String, font: UIFont, color: UIColor, in rect: CGRect) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil)
    }
}
