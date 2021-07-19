//
//  ReplicaStatusView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-29.
//

import os.log
import UIKit
import ActiveLabel
import FLAnimatedImage
import MetaTextView

final class ReplicaStatusView: UIView {

    static let avatarImageSize = CGSize(width: 42, height: 42)
    static let avatarImageCornerRadius: CGFloat = 4
    static let avatarToLabelSpacing: CGFloat = 5
    static let contentWarningBlurRadius: CGFloat = 12
    static let containerStackViewSpacing: CGFloat = 10

    let containerStackView = UIStackView()
    let headerContainerView = UIView()
    let authorContainerView = UIView()

    static let reblogIconImage: UIImage = {
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        let configuration = UIImage.SymbolConfiguration(font: font)
        let image = UIImage(systemName: "arrow.2.squarepath", withConfiguration: configuration)!.withTintColor(Asset.Colors.Label.secondary.color)
        return image
    }()

    static let replyIconImage: UIImage = {
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        let configuration = UIImage.SymbolConfiguration(font: font)
        let image = UIImage(systemName: "arrowshape.turn.up.left.fill", withConfiguration: configuration)!.withTintColor(Asset.Colors.Label.secondary.color)
        return image
    }()

    static func iconAttributedString(image: UIImage) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        let imageTextAttachment = NSTextAttachment()
        let imageAttribute = NSAttributedString(attachment: imageTextAttachment)
        imageTextAttachment.image = image
        attributedString.append(imageAttribute)
        return attributedString
    }

    let headerIconLabel: UILabel = {
        let label = UILabel()
        label.attributedText = ReplicaStatusView.iconAttributedString(image: ReplicaStatusView.reblogIconImage)
        return label
    }()

    let headerInfoLabel: ActiveLabel = {
        let label = ActiveLabel(style: .statusHeader)
        label.text = "Bob reblogged"
        label.layer.masksToBounds = false
        return label
    }()

    let avatarView: UIView = {
        let view = UIView()
        view.isAccessibilityElement = true
        view.accessibilityTraits = .button
        view.accessibilityLabel = L10n.Common.Controls.Status.showUserProfile
        return view
    }()
    let avatarImageView: UIImageView = FLAnimatedImageView()

    let nameLabel: ActiveLabel = {
        let label = ActiveLabel(style: .statusName)
        return label
    }()

    let nameTrialingDotLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.font = .systemFont(ofSize: 17)
        label.text = "·"
        label.isAccessibilityElement = false
        return label
    }()

    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "@alice"
        label.isAccessibilityElement = false
        return label
    }()

    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = Asset.Colors.Label.secondary.color
        label.text = "1d"
        return label
    }()

    let contentMetaText: MetaText = {
        let metaText = MetaText()
        metaText.textView.backgroundColor = .clear
        metaText.textView.isEditable = false
        metaText.textView.isSelectable = false
        metaText.textView.isScrollEnabled = false
        metaText.textView.textContainer.lineFragmentPadding = 0
        metaText.textView.textContainerInset = .zero
        metaText.textView.layer.masksToBounds = false
        return metaText
    }()

    let statusContainerStackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

}

extension ReplicaStatusView {
    private func _init() {
        // container: [reblog | author | status | action toolbar]
        // note: do not set spacing for nested stackView to avoid SDK layout conflict issue
        containerStackView.axis = .vertical
        // containerStackView.spacing = 10
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        containerStackView.setContentHuggingPriority(.required - 1, for: .vertical)
        containerStackView.setContentCompressionResistancePriority(.required - 1, for: .vertical)

        // header container: [icon | info]
        let headerContainerStackView = UIStackView()
        headerContainerStackView.axis = .horizontal
        headerContainerStackView.spacing = 4
        headerContainerStackView.addArrangedSubview(headerIconLabel)
        headerContainerStackView.addArrangedSubview(headerInfoLabel)
        headerIconLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        headerContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        headerContainerView.addSubview(headerContainerStackView)
        NSLayoutConstraint.activate([
            headerContainerStackView.topAnchor.constraint(equalTo: headerContainerView.topAnchor),
            headerContainerStackView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            headerContainerStackView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            headerContainerView.bottomAnchor.constraint(equalTo: headerContainerStackView.bottomAnchor, constant: ReplicaStatusView.containerStackViewSpacing).priority(.defaultHigh),
        ])
        containerStackView.addArrangedSubview(headerContainerView)
        defer {
            containerStackView.bringSubviewToFront(headerContainerView)
        }

        // author container: [avatar | author meta container | reveal button]
        let authorContainerStackView = UIStackView()
        authorContainerStackView.axis = .horizontal
        authorContainerStackView.spacing = ReplicaStatusView.avatarToLabelSpacing
        authorContainerStackView.distribution = .fill

        // avatar
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        authorContainerStackView.addArrangedSubview(avatarView)
        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: ReplicaStatusView.avatarImageSize.width).priority(.required - 1),
            avatarView.heightAnchor.constraint(equalToConstant: ReplicaStatusView.avatarImageSize.height).priority(.required - 1),
        ])
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),
        ])

        // author meta container: [title container | subtitle container]
        let authorMetaContainerStackView = UIStackView()
        authorContainerStackView.addArrangedSubview(authorMetaContainerStackView)
        authorMetaContainerStackView.axis = .vertical
        authorMetaContainerStackView.spacing = 4

        // title container: [display name | "·" | date | padding]
        let titleContainerStackView = UIStackView()
        authorMetaContainerStackView.addArrangedSubview(titleContainerStackView)
        titleContainerStackView.axis = .horizontal
        titleContainerStackView.spacing = 4
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        titleContainerStackView.addArrangedSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.heightAnchor.constraint(equalToConstant: 22).priority(.defaultHigh),
        ])
        titleContainerStackView.alignment = .firstBaseline
        titleContainerStackView.addArrangedSubview(nameTrialingDotLabel)
        titleContainerStackView.addArrangedSubview(dateLabel)
        let padding = UIView()
        titleContainerStackView.addArrangedSubview(padding) // padding
        nameLabel.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
        nameTrialingDotLabel.setContentHuggingPriority(.defaultHigh + 2, for: .horizontal)
        nameTrialingDotLabel.setContentCompressionResistancePriority(.required - 2, for: .horizontal)
        dateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        padding.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        padding.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)

        // subtitle container: [username]
        let subtitleContainerStackView = UIStackView()
        authorMetaContainerStackView.addArrangedSubview(subtitleContainerStackView)
        subtitleContainerStackView.axis = .horizontal
        subtitleContainerStackView.addArrangedSubview(usernameLabel)

        authorContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        authorContainerView.addSubview(authorContainerStackView)
        NSLayoutConstraint.activate([
            authorContainerStackView.topAnchor.constraint(equalTo: authorContainerView.topAnchor),
            authorContainerStackView.leadingAnchor.constraint(equalTo: authorContainerView.leadingAnchor),
            authorContainerStackView.trailingAnchor.constraint(equalTo: authorContainerView.trailingAnchor),
            authorContainerView.bottomAnchor.constraint(equalTo: authorContainerStackView.bottomAnchor, constant: ReplicaStatusView.containerStackViewSpacing).priority(.defaultHigh),
        ])
        containerStackView.addArrangedSubview(authorContainerView)

        // status container: [status]
        containerStackView.addArrangedSubview(statusContainerStackView)
        statusContainerStackView.axis = .vertical
        statusContainerStackView.spacing = 10

        // avoid overlay behind other views
        defer {
            containerStackView.bringSubviewToFront(authorContainerView)
        }

        // status
        statusContainerStackView.addArrangedSubview(contentMetaText.textView)
        contentMetaText.textView.setContentCompressionResistancePriority(.required - 1, for: .vertical)
    }
}

// MARK: - AvatarConfigurableView
extension ReplicaStatusView: AvatarConfigurableView {
    static var configurableAvatarImageSize: CGSize { return Self.avatarImageSize }
    static var configurableAvatarImageCornerRadius: CGFloat { return 4 }
    var configurableAvatarImageView: UIImageView? { avatarImageView }
    var configurableAvatarButton: UIButton? { nil }
}
