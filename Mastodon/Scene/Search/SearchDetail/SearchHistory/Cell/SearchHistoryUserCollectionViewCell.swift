//
//  SearchHistoryUserCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-20.
//

import UIKit
import Combine
import MastodonCore
import MastodonUI

final class SearchHistoryUserCollectionViewCell: UICollectionViewCell {
    
    var _disposeBag = Set<AnyCancellable>()
    
    let userView = UserView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        userView.prepareForReuse()
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

extension SearchHistoryUserCollectionViewCell {
    
    private func _init() {
        ThemeService.shared.currentTheme
            .map { $0.secondarySystemGroupedBackgroundColor }
            .sink { [weak self] backgroundColor in
                guard let self = self else { return }
                self.backgroundColor = backgroundColor
                self.setNeedsUpdateConfiguration()
            }
            .store(in: &_disposeBag)
        
        userView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(userView)
        NSLayoutConstraint.activate([
            userView.topAnchor.constraint(equalTo: contentView.topAnchor),
            userView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            userView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 16),
            userView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        
        var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
        backgroundConfiguration.backgroundColorTransformer = .init { _ in
            if state.isHighlighted || state.isSelected {
                return ThemeService.shared.currentTheme.value.tableViewCellSelectionBackgroundColor
            }
            return ThemeService.shared.currentTheme.value.secondarySystemGroupedBackgroundColor
        }
        self.backgroundConfiguration = backgroundConfiguration
    }
    
}
