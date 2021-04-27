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

protocol NotificationTableViewCellDelegate: AnyObject {
    var context: AppContext! { get }
    
    func parent() -> UIViewController
    
    func userAvatarDidPressed(notification: MastodonNotification)
    
    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, revealContentWarningButtonDidPressed button: UIButton)
    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, statusView: StatusView, playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
    
//    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, notification: MastodonNotification, acceptButtonDidPressed button: UIButton)
//    
//    func notificationStatusTableViewCell(_ cell: NotificationStatusTableViewCell, notification: MastodonNotification, denyButtonDidPressed button: UIButton)
    
}

final class NotificationTableViewCell: UITableViewCell {
    static let actionImageBorderWidth: CGFloat = 2
    
    var disposeBag = Set<AnyCancellable>()
    
    var delegate: NotificationTableViewCellDelegate?
    
    let avatatImageView: UIImageView = {
        let imageView = UIImageView()
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
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.brandBlue.color
        label.font = .systemFont(ofSize: 15, weight: .semibold)
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatatImageView.af.cancelImageRequest()
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

        avatarContainer.addSubview(avatatImageView)
        avatatImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatatImageView.heightAnchor.constraint(equalToConstant: 35).priority(.required - 1),
            avatatImageView.widthAnchor.constraint(equalToConstant: 35).priority(.required - 1),
            avatatImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            avatatImageView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor)
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
        denyButton.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.addArrangedSubview(acceptButton)
        buttonStackView.addArrangedSubview(rejectButton)
        containerStackView.addArrangedSubview(buttonStackView)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        actionImageBackground.layer.borderColor = Asset.Colors.Background.systemBackground.color.cgColor
    }
}
