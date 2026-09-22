//
//  VelonImageLoader.swift
//  velon
//

import UIKit

enum VelonImageLoader {
    static func image(named name: String) -> UIImage? {
        if let image = UIImage(named: name) {
            return image
        }
        let extensions = ["jpg", "jpeg", "png"]
        for ext in extensions {
            let candidates = [
                Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "assets/images"),
                Bundle.main.url(forResource: name, withExtension: ext)
            ]
            for url in candidates {
                if let url, let image = UIImage(contentsOfFile: url.path) {
                    return image
                }
            }
        }
        return nil
    }

    static func image(forCity city: VelonCity) -> UIImage? {
        if let relative = city.coverRelativePath,
           let url = VelonUserStore.shared.documentsRelativeURL(path: relative),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        return image(named: city.imageName)
    }

    static func apply(to imageView: UIImageView, named name: String, cornerRadius: CGFloat = 12) {
        imageView.image = image(named: name)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = cornerRadius
        imageView.backgroundColor = VelonTheme.separator
    }

    static func apply(to imageView: UIImageView, city: VelonCity, cornerRadius: CGFloat = 12) {
        imageView.image = image(forCity: city)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = cornerRadius
        imageView.backgroundColor = VelonTheme.separator
    }
}
