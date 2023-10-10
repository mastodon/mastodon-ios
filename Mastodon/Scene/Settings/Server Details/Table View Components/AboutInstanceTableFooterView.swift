// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MetaTextKit
import MastodonSDK
import MastodonMeta
import MastodonCore
import MastodonAsset
import MastodonLocalization

class AboutInstanceTableFooterView: UIView {
    let headlineLabel: UILabel
    let contentLabel: MetaLabel

    init() {

        headlineLabel = UILabel()
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: .systemFont(ofSize: 22, weight: .bold))

        contentLabel = MetaLabel(style: .aboutInstance)
        contentLabel.numberOfLines = 0
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: .zero)

        addSubview(headlineLabel)
        addSubview(contentLabel)

        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {

        let horizontalMargin = 16.0
        let verticalMargin = 24.0

        let constraints = [
            headlineLabel.topAnchor.constraint(equalTo: topAnchor, constant: verticalMargin),
            headlineLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalMargin),
            trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor, constant: horizontalMargin),

            contentLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 8),
            contentLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
            bottomAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: verticalMargin),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func update(with extendedDescription: Mastodon.Entity.ExtendedDescription) {
        headlineLabel.text = L10n.Scene.Settings.ServerDetails.AboutInstance.legalNotice

        let content = extendedDescription.content
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "\n\n", with: "\n")


        if let metaContent = try? MastodonMetaContent.convert(document: MastodonContent(content: content, emojis: [:])) {
            contentLabel.configure(content: metaContent)
        } else {
            let content = PlaintextMetaContent(string: content)
            contentLabel.configure(content: content)
        }
    }
}
