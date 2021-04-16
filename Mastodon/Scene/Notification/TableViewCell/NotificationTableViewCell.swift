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
        containerStackView.axis = .horizontal
        containerStackView.alignment = .center
        containerStackView.spacing = 4
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

        containerStackView.addArrangedSubview(avatarContainer)
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
        containerStackView.addArrangedSubview(nameLabel)
        actionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(actionLabel)
        nameLabel.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        actionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        actionImageBackground.layer.borderColor = Asset.Colors.Background.systemBackground.color.cgColor
    }
}
