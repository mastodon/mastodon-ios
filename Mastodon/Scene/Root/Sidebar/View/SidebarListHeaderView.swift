//
//  SidebarListHeaderView.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-10-28.
//

import UIKit
import MastodonAsset
import MastodonLocalization

final class SidebarListHeaderView: UICollectionReusableView {
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Asset.Scene.Sidebar.logo.image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .label
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension SidebarListHeaderView {
    private func _init() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            imageView.widthAnchor.constraint(equalToConstant: 44).priority(.required - 1),
            imageView.heightAnchor.constraint(equalToConstant: 44).priority(.required - 1),
        ])
    }
}
