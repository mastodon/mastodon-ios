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
        imageView.tintColor = Asset.Colors.Background.pure.color
        return imageView
    }()
    
    let actionImageBackground: UIView = {
        let view = UIView()
        view.layer.cornerRadius = (24 + NotificationTableViewCell.actionImageBorderWidth) / 2
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        view.layer.borderWidth = NotificationTableViewCell.actionImageBorderWidth
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
        selectionStyle = .none
        
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
        avatatImageView.pin(top: 12, left: 12, bottom: nil, right: nil)
        
        container.addSubview(actionImageBackground)
        actionImageBackground.pin(toSize: CGSize(width: 24 + NotificationTableViewCell.actionImageBorderWidth, height: 24 + NotificationTableViewCell.actionImageBorderWidth))
        actionImageBackground.pin(top: 33, left: 33, bottom: nil, right: nil)
        
        actionImageBackground.addSubview(actionImageView)
        actionImageView.constrainToCenter()

        container.addSubview(nameLabel)
        nameLabel.constrain([
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            container.bottomAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 24),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 61)
        ])
        
        container.addSubview(actionLabel)
        actionLabel.constrain([
            actionLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
            actionLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            container.trailingAnchor.constraint(greaterThanOrEqualTo: actionLabel.trailingAnchor, constant: 4).priority(.defaultLow)
        ])
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        actionImageBackground.layer.borderColor = Asset.Colors.Background.pure.color.cgColor
    }
}
