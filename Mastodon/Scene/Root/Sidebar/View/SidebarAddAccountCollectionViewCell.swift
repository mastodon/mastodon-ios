//
//  SidebarAddAccountCollectionViewCell.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-27.
//

import UIKit
import MastodonAsset
import MastodonLocalization

final class SidebarAddAccountCollectionViewCell: UICollectionViewListCell {
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension SidebarAddAccountCollectionViewCell {
    
    private func _init() { }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        
        var newBackgroundConfiguration = UIBackgroundConfiguration.listSidebarCell().updated(for: state)
        
        // Customize the background color to use the tint color when the cell is highlighted or selected.
        if state.isSelected || state.isHighlighted {
            newBackgroundConfiguration.backgroundColor = Asset.Colors.Brand.blurple.color
        }
        if state.isHighlighted {
            newBackgroundConfiguration.backgroundColorTransformer = .init { $0.withAlphaComponent(0.8) }
        }

        backgroundConfiguration = newBackgroundConfiguration
    }
}
