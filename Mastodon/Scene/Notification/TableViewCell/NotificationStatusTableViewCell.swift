//
//  NotificationStatusTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/14.
//

import Combine
import Foundation
import UIKit

final class NotificationStatusTableViewCell: UITableViewCell {
    static let actionImageBorderWidth: CGFloat = 2
    
    static let statusPadding = UIEdgeInsets(top: 50, left: 73, bottom: 24, right: 24)
    var disposeBag = Set<AnyCancellable>()
    var pollCountdownSubscription: AnyCancellable?
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
        imageView.tintColor = Asset.Colors.Background.pure.color
        return imageView
    }()
    
    let actionImageBackground: UIView = {
        let view = UIView()
        view.layer.cornerRadius = (24 + NotificationStatusTableViewCell.actionImageBorderWidth) / 2
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        view.layer.borderWidth = NotificationStatusTableViewCell.actionImageBorderWidth
        view.layer.borderColor = Asset.Colors.Background.pure.color.cgColor
        view.tintColor = Asset.Colors.Background.pure.color
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
    
    let statusBorder: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 6
        view.layer.borderWidth = 2
        view.layer.cornerCurve = .continuous
        view.layer.borderColor = Asset.Colors.Border.notification.color.cgColor
        view.clipsToBounds = true
        return view
    }()
    
    let statusView = StatusView()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatatImageView.af.cancelImageRequest()
        statusView.isStatusTextSensitive = false
        statusView.cleanUpContentWarning()
        statusView.pollTableView.dataSource = nil
        statusView.playerContainerView.reset()
        statusView.playerContainerView.isHidden = true

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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async {
            self.statusView.drawContentWarningImageView()
        }
    }
}

extension NotificationStatusTableViewCell {
    func configure() {
        
        let container = UIView()
        container.backgroundColor = .clear
        contentView.addSubview(container)
        container.constrain([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        container.addSubview(avatatImageView)
        avatatImageView.pin(toSize: CGSize(width: 35, height: 35))
        avatatImageView.pin(top: 12, left: 0, bottom: nil, right: nil)
        
        container.addSubview(actionImageBackground)
        actionImageBackground.pin(toSize: CGSize(width: 24 + NotificationTableViewCell.actionImageBorderWidth, height: 24 + NotificationTableViewCell.actionImageBorderWidth))
        actionImageBackground.pin(top: 33, left: 21, bottom: nil, right: nil)
        
        actionImageBackground.addSubview(actionImageView)
        actionImageView.constrainToCenter()

        container.addSubview(nameLabel)
        nameLabel.constrain([
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 61)
        ])
        
        container.addSubview(actionLabel)
        actionLabel.constrain([
            actionLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
            actionLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            container.trailingAnchor.constraint(greaterThanOrEqualTo: actionLabel.trailingAnchor, constant: 4)
        ])
        
        statusView.contentWarningBlurContentImageView.backgroundColor = Asset.Colors.Background.secondaryGroupedSystemBackground.color
        statusView.isUserInteractionEnabled = false
        // remove item don't display
        statusView.actionToolbarContainer.isHidden = true
        statusView.avatarView.isHidden = true
        statusView.usernameLabel.isHidden = true
        
        container.addSubview(statusBorder)
        statusBorder.pin(top: 40, left: 63, bottom: 14, right: 14)
        
        container.addSubview(statusView)
        statusView.pin(top: NotificationStatusTableViewCell.statusPadding.top, left: NotificationStatusTableViewCell.statusPadding.left, bottom: NotificationStatusTableViewCell.statusPadding.bottom, right: NotificationStatusTableViewCell.statusPadding.right)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        statusBorder.layer.borderColor = Asset.Colors.Border.notification.color.cgColor
        actionImageBackground.layer.borderColor = Asset.Colors.Background.pure.color.cgColor
    }
}
