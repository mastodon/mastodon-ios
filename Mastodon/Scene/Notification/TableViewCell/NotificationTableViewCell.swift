//
//  NotificationTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import Combine
import Foundation
import UIKit

protocol NotificationTableViewCellDelegate: class {
    var context: AppContext! { get }
    
    func parent() -> UIViewController
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
        imageView.tintColor = Asset.Colors.Background.searchResult.color
        return imageView
    }()
    
    let actionImageBackground: UIView = {
        let view = UIView()
        view.layer.cornerRadius = (24 + NotificationTableViewCell.actionImageBorderWidth) / 2
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        view.layer.borderWidth = NotificationTableViewCell.actionImageBorderWidth
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
    
    var nameLabelTop: NSLayoutConstraint!
    var nameLabelBottom: NSLayoutConstraint!
    
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

extension NotificationTableViewCell {
    func configure() {
        selectionStyle = .none
        
        contentView.addSubview(avatatImageView)
        avatatImageView.pin(toSize: CGSize(width: 35, height: 35))
        avatatImageView.pin(top: 12, left: 12, bottom: nil, right: nil)
        
        contentView.addSubview(actionImageBackground)
        actionImageBackground.pin(toSize: CGSize(width: 24 + NotificationTableViewCell.actionImageBorderWidth, height: 24 + NotificationTableViewCell.actionImageBorderWidth))
        actionImageBackground.pin(top: 33, left: 33, bottom: nil, right: nil)
        
        actionImageBackground.addSubview(actionImageView)
        actionImageView.constrainToCenter()
        
        nameLabelTop = nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24)
        nameLabelBottom = contentView.bottomAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 24)
        contentView.addSubview(nameLabel)
        nameLabel.constrain([
            nameLabelTop,
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 61)
        ])
        
        contentView.addSubview(actionLabel)
        actionLabel.constrain([
            actionLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
            actionLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            contentView.trailingAnchor.constraint(equalTo: actionLabel.trailingAnchor, constant: 4).priority(.defaultLow)
        ])
        
        statusView.contentWarningBlurContentImageView.backgroundColor = Asset.Colors.Background.secondaryGroupedSystemBackground.color
        
    }
    
    public func nameLabelLayoutIn(center: Bool) {
        if center {
            nameLabelTop.constant = 24
            NSLayoutConstraint.activate([nameLabelBottom])
            statusView.removeFromSuperview()
            statusContainer.removeFromSuperview()
        } else {
            nameLabelTop.constant = 12
            NSLayoutConstraint.deactivate([nameLabelBottom])
            addStatusAndContainer()
        }
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
