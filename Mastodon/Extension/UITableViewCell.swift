//
//  UITableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-5.
//

import UIKit

extension UITableViewCell {

    /// The color of the cell when it is selected.
    @objc dynamic var selectionColor: UIColor? {
        get { return selectedBackgroundView?.backgroundColor }
        set {
            guard selectionStyle != .none else { return }
            let view = UIView()
            view.backgroundColor = newValue
            selectedBackgroundView = view
        }
    }
}
