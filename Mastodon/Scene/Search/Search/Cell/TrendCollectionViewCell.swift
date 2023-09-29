//
//  TrendCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-18.
//

import UIKit
import Combine
import MetaTextKit
import MastodonAsset
import MastodonCore
import MastodonUI

final class TrendCollectionViewCell: UICollectionViewCell {
    
    var _disposeBag = Set<AnyCancellable>()
    
    let trendView = TrendView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension TrendCollectionViewCell {
    
    private func _init() {
        trendView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(trendView)
        trendView.pinToParent()
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        
        var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
        backgroundConfiguration.backgroundColorTransformer = .init { _ in
            if state.isHighlighted || state.isSelected {
                return SystemTheme.tableViewCellSelectionBackgroundColor
            }
            return .secondarySystemGroupedBackground
        }
        self.backgroundConfiguration = backgroundConfiguration
    }
    
}

