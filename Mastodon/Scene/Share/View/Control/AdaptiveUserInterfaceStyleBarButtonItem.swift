//
//  AdaptiveUserInterfaceStyleBarButtonItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-13.
//

import UIKit

final class AdaptiveUserInterfaceStyleBarButtonItem: UIBarButtonItem {
    
    let button = AdaptiveCustomButton()
    
    init(lightImage: UIImage, darkImage: UIImage) {
        super.init()
        button.setImage(light: lightImage, dark: darkImage)
        self.customView = button
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}

extension AdaptiveUserInterfaceStyleBarButtonItem {
    class AdaptiveCustomButton: UIButton {
        
        var lightImage: UIImage?
        var darkImage: UIImage?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            _init()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            _init()
        }
        
        private func _init() {
            adjustsImageWhenHighlighted = false
        }
        
        override var isHighlighted: Bool {
            didSet {
                alpha = isHighlighted ? 0.6 : 1
            }
        }
        
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            resetImage()
        }
        
        func setImage(light: UIImage, dark: UIImage) {
            lightImage = light
            darkImage = dark
            resetImage()
        }
        
        private func resetImage() {
            switch traitCollection.userInterfaceStyle {
            case .light:
                setImage(lightImage, for: .normal)
            case .dark,
                 .unspecified:
                setImage(darkImage, for: .normal)
            @unknown default:
                assertionFailure()
            }
        }
        
    }
}
