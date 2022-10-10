//
//  PickServerLoaderTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-13.
//

import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

public final class PickServerLoaderTableViewCell: TimelineLoaderTableViewCell {
    
    let containerView: UIView = {
        let view = UIView()
        view.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 10, right: 16)
        view.backgroundColor = .clear
        return view
    }()
    
    let emptyStatusLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Scene.ServerPicker.EmptyState.noResults
        label.textColor = Asset.Colors.Label.secondary.color
        label.textAlignment = .center
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 14, weight: .semibold))
        return label
    }()
    
    public override func _init() {
        super._init()
                

        // Set background view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        
        emptyStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(emptyStatusLabel)
        NSLayoutConstraint.activate([
            emptyStatusLabel.leadingAnchor.constraint(equalTo: containerView.readableContentGuide.leadingAnchor),
            containerView.readableContentGuide.trailingAnchor.constraint(equalTo: emptyStatusLabel.trailingAnchor),
            emptyStatusLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])
        emptyStatusLabel.isHidden = true
        
        contentView.bringSubviewToFront(stackView)
        activityIndicatorView.isHidden = false
        startAnimating()
    }

}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct PickServerLoaderTableViewCell_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            PickServerLoaderTableViewCell()
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }
    
}

#endif
