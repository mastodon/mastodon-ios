// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonLocalization

final class LogoutOfAllAccountsCell: UITableViewCell {

    static let reuseIdentifier = "LogoutOfAllAccountsCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        var configuration = defaultContentConfiguration()
        configuration.image = UIImage(systemName: "rectangle.portrait.and.arrow.forward")
        configuration.imageProperties.tintColor = .systemRed

        configuration.text = L10n.Scene.AccountList.logoutAllAccounts
        configuration.textProperties.color = .systemRed
        configuration.textProperties.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .regular), maximumPointSize: 22)
        configuration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)
        backgroundColor = .secondarySystemGroupedBackground

        self.contentConfiguration = configuration
        accessibilityTraits.insert(.button)

    }

    required init?(coder: NSCoder) { fatalError() }
}

