//
//  PickServerViewController.swift
//  Mastodon
//
//  Created by 高原 on 2021/2/20.
//

import UIKit

class PickServerViewController: UIViewController {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 34)
        label.textColor = Asset.Colors.Label.black.color
        label.text = L10n.Scene.ServerPicker.title
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
}
