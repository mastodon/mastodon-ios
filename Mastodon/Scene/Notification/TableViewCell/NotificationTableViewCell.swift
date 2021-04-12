//
//  NotificationTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import Foundation
import UIKit
import Combine


final class NotificationTableViewCell: UITableViewCell {
    
    static let actionImageBorderWidth: CGFloat = 3
    
    var disposeBag = Set<AnyCancellable>()
    
    let avatatImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 4
        imageView.layer.cornerCurve = .continuous
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let actionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 4
        imageView.layer.cornerCurve = .continuous
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = NotificationTableViewCell.actionImageBorderWidth
        imageView.layer.borderColor = Asset.Colors.Background.searchResult.color.cgColor
        imageView.tintColor = Asset.Colors.Background.searchResult.color
        return imageView
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatatImageView.af.cancelImageRequest()
        
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
        contentView.addSubview(avatatImageView)
        avatatImageView.pin(toSize: CGSize(width: 35, height: 35))
        avatatImageView.pin(top: 12, left: 12, bottom: nil, right: nil)
        
        contentView.addSubview(actionImageView)
        actionImageView.pin(toSize: CGSize(width: 24, height: 24))
        actionImageView.pin(top: 33, left: 33, bottom: nil, right: nil)
        
        nameLabelTop = nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor)
        nameLabel.constrain([
            nameLabelTop,
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 61)
        ])
        
        actionLabel.constrain([
            actionLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 4),
            actionLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: actionLabel.trailingAnchor, constant: 4)
        ])
    }
    
    public func nameLabelLayoutIn(center: Bool) {
        if center {
            nameLabelTop.constant = 24
        } else {
            nameLabelTop.constant = 12
        }
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        self.actionImageView.layer.borderColor = Asset.Colors.Background.searchResult.color.cgColor
    }
}
