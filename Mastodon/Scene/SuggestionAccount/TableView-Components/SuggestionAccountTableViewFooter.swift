// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonUI
import MastodonAsset

protocol SuggestionAccountTableViewFooterDelegate: AnyObject {
    func followAll(_ footerView: SuggestionAccountTableViewFooter)
}

class SuggestionAccountTableViewFooter: UITableViewHeaderFooterView {
    static let reuseIdentifier = "SuggestionAccountTableViewFooter"

    weak var delegate: SuggestionAccountTableViewFooterDelegate?

    let followAllButton: FollowButton

    override init(reuseIdentifier: String?) {

        //TODO: Check if we can use UIButton.configuration here instead?
        followAllButton = FollowButton()
        followAllButton.translatesAutoresizingMaskIntoConstraints = false
        followAllButton.setTitle("Follow All", for: .normal)
        followAllButton.setBackgroundColor(Asset.Colors.Button.userFollow.color, for: .normal)
        followAllButton.setTitleColor(.white, for: .normal)
        followAllButton.contentEdgeInsets = .init(horizontal: 20, vertical: 12)
        followAllButton.cornerRadius = 10
        followAllButton.titleLabel?.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .boldSystemFont(ofSize: 15))

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
