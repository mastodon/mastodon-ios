// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonUI

class SearchResultsProfileTableViewCell: UITableViewCell {
    static let reuseIdentifier = "SearchResultsProfileTableViewCell"

    let condensedUserView: CondensedUserView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        condensedUserView = CondensedUserView(frame: .zero)
        condensedUserView.translatesAutoresizingMaskIntoConstraints = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(condensedUserView)
        condensedUserView.pinToParent()
        backgroundColor = .secondarySystemGroupedBackground
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()

        condensedUserView.prepareForReuse()
    }
}
