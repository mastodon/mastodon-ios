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
        imageView.tintColor = Asset.Colors.Background.searchResult.color
        return imageView
    }()
    
    let actionImageBackground: UIView = {
        let view = UIView()
        view.layer.cornerRadius = (24 + NotificationStatusTableViewCell.actionImageBorderWidth) / 2
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        view.layer.borderWidth = NotificationStatusTableViewCell.actionImageBorderWidth
        view.layer.borderColor = Asset.Colors.Background.searchResult.color.cgColor
        view.tintColor = Asset.Colors.Background.searchResult.color
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
    
    let statusContainer: UIView = {
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
        selectionStyle = .none
        
        contentView.addSubview(avatatImageView)
        avatatImageView.pin(toSize: CGSize(width: 35, height: 35))
        avatatImageView.pin(top: 12, left: 12, bottom: nil, right: nil)
        
        contentView.addSubview(actionImageBackground)
        actionImageBackground.pin(toSize: CGSize(width: 24 + NotificationStatusTableViewCell.actionImageBorderWidth, height: 24 + NotificationStatusTableViewCell.actionImageBorderWidth))
        actionImageBackground.pin(top: 33, left: 33, bottom: nil, right: nil)
        
        actionImageBackground.addSubview(actionImageView)
        actionImageView.constrainToCenter()
        
        contentView.addSubview(nameLabel)
        nameLabel.constrain([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 61)
        ])
        
        contentView.addSubview(actionLabel)
        actionLabel.constrain([
            actionLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
            actionLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            contentView.trailingAnchor.constraint(equalTo: actionLabel.trailingAnchor, constant: 4).priority(.defaultLow)
        ])
        
        statusView.contentWarningBlurContentImageView.backgroundColor = Asset.Colors.Background.secondaryGroupedSystemBackground.color
        addStatusAndContainer()
    }
    
    func addStatusAndContainer() {
        contentView.addSubview(statusContainer)
        statusContainer.pin(top: 40, left: 63, bottom: 14, right: 14)
        
        contentView.addSubview(statusView)
        statusView.pin(top: 40 + 12, left: 63 + 12, bottom: 14 + 12, right: 14 + 12)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        statusContainer.layer.borderColor = Asset.Colors.Border.notification.color.cgColor
        actionImageBackground.layer.borderColor = Asset.Colors.Background.searchResult.color.cgColor
    }
}
