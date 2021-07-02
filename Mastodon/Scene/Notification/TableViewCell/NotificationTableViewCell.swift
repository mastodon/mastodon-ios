//
//  NotificationTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import Combine
import CoreDataStack
import Foundation
import UIKit
import Meta
import MetaTextView
import ActiveLabel
import FLAnimatedImage
import Nuke

protocol NotificationTableViewCellDelegate: AnyObject {
    var context: AppContext! { get }
    
    func parent() -> UIViewController
    
    func userAvatarDidPressed(notification: MastodonNotification)
    func userNameLabelDidPressed(notification: MastodonNotification)
    
    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, revealContentWarningButtonDidPressed button: UIButton)
    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta)

    func notificationTableViewCell(_ cell: NotificationTableViewCell, notification: MastodonNotification, acceptButtonDidPressed button: UIButton)
    func notificationTableViewCell(_ cell: NotificationTableViewCell, notification: MastodonNotification, rejectButtonDidPressed button: UIButton)
    
}

final class NotificationTableViewCell: UITableViewCell {
    static let actionImageBorderWidth: CGFloat = 2
    
    var disposeBag = Set<AnyCancellable>()
    
    var delegate: NotificationTableViewCellDelegate?

    var avatarImageViewTask: ImageTask?
    let avatarImageView: UIImageView = {
        let imageView = FLAnimatedImageView()
        imageView.layer.cornerRadius = 4
        imageView.layer.cornerCurve = .continuous
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let actionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Asset.Colors.Background.systemBackground.color
        return imageView
    }()
    
    let actionImageBackground: UIView = {
        let view = UIView()
        view.layer.cornerRadius = (24 + NotificationTableViewCell.actionImageBorderWidth) / 2
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        view.layer.borderWidth = NotificationTableViewCell.actionImageBorderWidth
        view.layer.borderColor = Asset.Colors.Background.systemBackground.color.cgColor
        view.tintColor = Asset.Colors.Background.systemBackground.color
        return view
    }()
    
    let avatarContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    let actionLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular), maximumPointSize: 20)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    let nameLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.textColor = Asset.Colors.brandBlue.color
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold), maximumPointSize: 20)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    let acceptButton: UIButton = {
        let button = UIButton(type: .custom)
        let actionImage = UIImage(systemName: "checkmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold))?.withRenderingMode(.alwaysTemplate)
        button.setImage(actionImage, for: .normal)
        button.tintColor = Asset.Colors.Label.secondary.color
        return button
    }()
    
    let rejectButton: UIButton = {
        let button = UIButton(type: .custom)
        let actionImage = UIImage(systemName: "xmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold))?.withRenderingMode(.alwaysTemplate)
        button.setImage(actionImage, for: .normal)
        button.tintColor = Asset.Colors.Label.secondary.color
        return button
    }()
    
    let buttonStackView = UIStackView()
    
    let separatorLine = UIView.separatorLine
    
    var separatorLineToEdgeLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToEdgeTrailingLayoutConstraint: NSLayoutConstraint!
    
    var separatorLineToMarginLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToMarginTrailingLayoutConstraint: NSLayoutConstraint!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageViewTask?.cancel()
        avatarImageViewTask = nil
        disposeBag.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

extension NotificationTableViewCell {
    func configure() {
        backgroundColor = Asset.Colors.Background.systemBackground.color
        selectedBackgroundView = {
            let view = UIView()
            view.backgroundColor = Asset.Colors.Background.Cell.highlight.color
            return view
        }()
        
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.alignment = .fill
        containerStackView.layoutMargins = UIEdgeInsets(top: 14, left: 0, bottom: 12, right: 0)
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor),
        ])
        
        let horizontalStackView = UIStackView()
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 6

        horizontalStackView.addArrangedSubview(avatarContainer)
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarContainer.heightAnchor.constraint(equalToConstant: 47).priority(.required - 1),
            avatarContainer.widthAnchor.constraint(equalToConstant: 47).priority(.required - 1)
        ])

        avatarContainer.addSubview(avatarImageView)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarImageView.heightAnchor.constraint(equalToConstant: 35).priority(.required - 1),
            avatarImageView.widthAnchor.constraint(equalToConstant: 35).priority(.required - 1),
            avatarImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor)
        ])

        avatarContainer.addSubview(actionImageBackground)
        actionImageBackground.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionImageBackground.heightAnchor.constraint(equalToConstant: 24 + NotificationTableViewCell.actionImageBorderWidth).priority(.required - 1),
            actionImageBackground.widthAnchor.constraint(equalToConstant: 24 + NotificationTableViewCell.actionImageBorderWidth).priority(.required - 1),
            actionImageBackground.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
            actionImageBackground.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor)
        ])

        avatarContainer.addSubview(actionImageView)
        actionImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionImageView.centerXAnchor.constraint(equalTo: actionImageBackground.centerXAnchor),
            actionImageView.centerYAnchor.constraint(equalTo: actionImageBackground.centerYAnchor)
        ])
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.addArrangedSubview(nameLabel)
        actionLabel.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.addArrangedSubview(actionLabel)
        nameLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        nameLabel.setContentHuggingPriority(.required - 1, for: .horizontal)
        actionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        containerStackView.addArrangedSubview(horizontalStackView)
        
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        rejectButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.addArrangedSubview(acceptButton)
        buttonStackView.addArrangedSubview(rejectButton)
        containerStackView.addArrangedSubview(buttonStackView)
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        separatorLineToEdgeLeadingLayoutConstraint = separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        separatorLineToEdgeTrailingLayoutConstraint = separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        separatorLineToMarginLeadingLayoutConstraint = separatorLine.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor)
        separatorLineToMarginTrailingLayoutConstraint = separatorLine.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor)
        NSLayoutConstraint.activate([
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
        ])
        resetSeparatorLineLayout()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        actionImageBackground.layer.borderColor = Asset.Colors.Background.systemBackground.color.cgColor
        resetSeparatorLineLayout()
    }
}

extension NotificationTableViewCell {
    
    private func resetSeparatorLineLayout() {
        separatorLineToEdgeLeadingLayoutConstraint.isActive = false
        separatorLineToEdgeTrailingLayoutConstraint.isActive = false
        separatorLineToMarginLeadingLayoutConstraint.isActive = false
        separatorLineToMarginTrailingLayoutConstraint.isActive = false
        
        if traitCollection.userInterfaceIdiom == .phone {
            // to edge
            NSLayoutConstraint.activate([
                separatorLineToEdgeLeadingLayoutConstraint,
                separatorLineToEdgeTrailingLayoutConstraint,
            ])
        } else {
            if traitCollection.horizontalSizeClass == .compact {
                // to edge
                NSLayoutConstraint.activate([
                    separatorLineToEdgeLeadingLayoutConstraint,
                    separatorLineToEdgeTrailingLayoutConstraint,
                ])
            } else {
                // to margin
                NSLayoutConstraint.activate([
                    separatorLineToMarginLeadingLayoutConstraint,
                    separatorLineToMarginTrailingLayoutConstraint,
                ])
            }
        }
    }
    
}
