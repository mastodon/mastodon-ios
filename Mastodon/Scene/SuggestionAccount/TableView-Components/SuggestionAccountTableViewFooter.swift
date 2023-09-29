// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonUI
import MastodonAsset
import MastodonLocalization

protocol SuggestionAccountTableViewFooterDelegate: AnyObject {
    func followAll(_ footerView: SuggestionAccountTableViewFooter)
}

class SuggestionAccountTableViewFooter: UITableViewHeaderFooterView {
    static let reuseIdentifier = "SuggestionAccountTableViewFooter"

    weak var delegate: SuggestionAccountTableViewFooterDelegate?

    let followAllButton: UIButton

    override init(reuseIdentifier: String?) {

        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.baseForegroundColor = .white
        buttonConfiguration.baseBackgroundColor = Asset.Colors.Button.userFollow.color
        buttonConfiguration.background.cornerRadius = 10
        buttonConfiguration.attributedTitle = AttributedString(L10n.Scene.SuggestionAccount.followAll, attributes: AttributeContainer([.font: UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .boldSystemFont(ofSize: 15))]))
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)

        followAllButton = UIButton(configuration: buttonConfiguration)
        followAllButton.isEnabled = false
        followAllButton.translatesAutoresizingMaskIntoConstraints = false
        followAllButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        followAllButton.setContentHuggingPriority(.required, for: .horizontal)

        super.init(reuseIdentifier: reuseIdentifier)

        contentView.addSubview(followAllButton)
        setupConstraints()

        followAllButton.addTarget(self, action: #selector(SuggestionAccountTableViewFooter.followAll(_:)), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            followAllButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            followAllButton.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: followAllButton.trailingAnchor),
            contentView.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: followAllButton.bottomAnchor, constant: 16),

            followAllButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 96),
            followAllButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    //MARK: - Actions
    @objc func followAll(_ sender: UIButton) {
        delegate?.followAll(self)
    }
}
