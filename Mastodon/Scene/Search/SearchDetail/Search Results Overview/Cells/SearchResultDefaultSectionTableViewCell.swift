// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

class SearchResultDefaultSectionTableViewCell: UITableViewCell {
    static let reuseIdentifier = "SearchResultDefaultSectionTableViewCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .secondarySystemGroupedBackground
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(item: SearchResultOverviewItem.DefaultSectionEntry) {
        var content = UIListContentConfiguration.cell()
        content.image = item.icon
        content.text = item.title
        content.imageProperties.tintColor = Asset.Colors.Brand.blurple.color

        contentConfiguration = content
    }

    func configure(item: SearchResultOverviewItem.SuggestionSectionEntry) {
        var content = UIListContentConfiguration.cell()
        content.image = item.icon
        content.text = item.title
        content.imageProperties.tintColor = Asset.Colors.Brand.blurple.color

        contentConfiguration = content
    }
}
