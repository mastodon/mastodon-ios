//
//  UIButton.swift
//  
//
//  Created by MainasuK on 2022-1-17.
//

import UIKit

extension UIButton {
    @available(iOS, deprecated: 15.0, message: "This method is ignored when using UIButtonConfiguration. The effect of this method can be replicated via UIButtonConfiguration.contentInset and UIButtonConfiguration.imagePadding.")
    public func setInsets(
        forContentPadding contentPadding: UIEdgeInsets,
        imageTitlePadding: CGFloat
    ) {
        switch UIApplication.shared.userInterfaceLayoutDirection {
        case .rightToLeft:
            self.contentEdgeInsets = UIEdgeInsets(
                top: contentPadding.top,
                left: contentPadding.left + imageTitlePadding,
                bottom: contentPadding.bottom,
                right: contentPadding.right
            )
            self.titleEdgeInsets = UIEdgeInsets(
                top: 0,
                left: -imageTitlePadding,
                bottom: 0,
                right: imageTitlePadding
            )
        default:
            self.contentEdgeInsets = UIEdgeInsets(
                top: contentPadding.top,
                left: contentPadding.left,
                bottom: contentPadding.bottom,
                right: contentPadding.right + imageTitlePadding
            )
            self.titleEdgeInsets = UIEdgeInsets(
                top: 0,
                left: imageTitlePadding,
                bottom: 0,
                right: -imageTitlePadding
            )
        }
    }
}

extension UIButton {
    public func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        self.setBackgroundImage(
            UIImage.placeholder(color: color),
            for: state
        )
    }
}
