// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset
import MastodonLocalization

final class AddAccountTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        var configuration = defaultContentConfiguration()
        configuration.image = UIImage(systemName: "plus")
        configuration.imageProperties.tintColor = Asset.Colors.Label.primary.color

        configuration.text = L10n.Scene.AccountList.addAccount
        configuration.textProperties.color = Asset.Colors.Label.primary.color
        configuration.textProperties.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .regular), maximumPointSize: 22)
        configuration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)
        backgroundColor = .secondarySystemGroupedBackground

        self.contentConfiguration = configuration
        accessibilityTraits.insert(.button)
    }

    required init?(coder: NSCoder) { fatalError() }

}
