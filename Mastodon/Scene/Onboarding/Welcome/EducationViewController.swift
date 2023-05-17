// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonLocalization

class EducationViewController: UIViewController {
    let mastodonLabel: UILabel
    let mastodonExplanation: UILabel
    let serversLabel: UILabel
    let serversExplanation: UILabel

    private let contentStackView: UIStackView
    private let contentScrollView: UIScrollView

    init() {
        mastodonLabel = UILabel()
        mastodonLabel.numberOfLines = 0
        mastodonLabel.adjustsFontForContentSizeCategory = true
        mastodonLabel.text = L10n.Scene.Welcome.Education.Mastodon.title
        mastodonLabel.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: .systemFont(ofSize: 22, weight: .bold))
        mastodonLabel.textColor = .label

        mastodonExplanation = UILabel()
        mastodonExplanation.numberOfLines = 0
        mastodonExplanation.adjustsFontForContentSizeCategory = true
        mastodonExplanation.text = L10n.Scene.Welcome.Education.Mastodon.description
        mastodonExplanation.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        mastodonExplanation.textColor = .label

        serversLabel = UILabel()
        serversLabel.numberOfLines = 0
        serversLabel.adjustsFontForContentSizeCategory = true
        serversLabel.text = L10n.Scene.Welcome.Education.Servers.title
        serversLabel.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: .systemFont(ofSize: 22, weight: .bold))
        serversLabel.textColor = .label

        serversExplanation = UILabel()
        serversExplanation.numberOfLines = 0
        serversExplanation.adjustsFontForContentSizeCategory = true
        serversExplanation.text = L10n.Scene.Welcome.Education.Servers.description
        serversExplanation.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        serversExplanation.textColor = .label

        contentStackView = UIStackView(arrangedSubviews: [mastodonLabel, mastodonExplanation, serversLabel, serversExplanation])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.alignment = .leading

        contentStackView.setCustomSpacing(2, after: mastodonLabel)
        contentStackView.setCustomSpacing(24, after: mastodonExplanation)
        contentStackView.setCustomSpacing(2, after: serversLabel)

        contentScrollView = UIScrollView()
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        contentScrollView.addSubview(contentStackView)

        super.init(nibName: nil, bundle: nil)

        view.addSubview(contentScrollView)
        view.backgroundColor = .systemBackground

        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            contentStackView.topAnchor.constraint(equalTo: contentScrollView.topAnchor, constant: 32),
            contentStackView.leadingAnchor.constraint(equalTo: contentScrollView.leadingAnchor, constant: 16),
            contentScrollView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: 16),
            contentScrollView.bottomAnchor.constraint(greaterThanOrEqualTo: contentStackView.bottomAnchor, constant: 32),

            contentScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentScrollView.trailingAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: contentScrollView.bottomAnchor),

            contentStackView.widthAnchor.constraint(equalTo: contentScrollView.widthAnchor, constant: -32),

        ]

        NSLayoutConstraint.activate(constraints)
    }
}
