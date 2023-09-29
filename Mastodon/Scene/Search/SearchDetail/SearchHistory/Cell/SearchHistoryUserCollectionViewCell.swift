// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonUI
import MastodonCore

class SearchHistoryUserCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "SearchHistoryUserCollectionViewCell"

    let condensedUserView: CondensedUserView

    override init(frame: CGRect) {
        condensedUserView = CondensedUserView(frame: .zero)
        condensedUserView.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: frame)

        contentView.addSubview(condensedUserView)
        condensedUserView.pinToParent()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()

        condensedUserView.prepareForReuse()
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)

        var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
        backgroundConfiguration.backgroundColorTransformer = .init { _ in
            if state.isHighlighted || state.isSelected {
                return SystemTheme.tableViewCellSelectionBackgroundColor
            } else {
                return .secondarySystemGroupedBackground
            }
        }
        
        self.backgroundConfiguration = backgroundConfiguration

    }
}

