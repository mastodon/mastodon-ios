//
//  UserTableViewCell.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import CoreData
import CoreDataStack
import MastodonSDK
import UIKit
import MetaTextKit
import MastodonMeta
import FLAnimatedImage

protocol UserTableViewCellDelegate: AnyObject { }

final class UserTableViewCell: UITableViewCell {
    
    weak var delegate: UserTableViewCellDelegate?
    
    let avatarImageView: AvatarImageView = {
        let imageView = AvatarImageView()
        imageView.tintColor = Asset.Colors.Label.primary.color
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let nameLabel = MetaLabel(style: .statusName)
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()
    
    let separatorLine = UIView.separatorLine
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension UserTableViewCell {
    
    private func _init() {
        let containerStackView = UIStackView()
        containerStackView.axis = .horizontal
        containerStackView.distribution = .fill
        containerStackView.spacing = 12
        containerStackView.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 42).priority(.required - 1),
            avatarImageView.heightAnchor.constraint(equalToConstant: 42).priority(.required - 1),
        ])
        
        let textStackView = UIStackView()
        textStackView.axis = .vertical
        textStackView.distribution = .fill
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        textStackView.addArrangedSubview(nameLabel)
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        textStackView.addArrangedSubview(usernameLabel)
        usernameLabel.setContentHuggingPriority(.defaultLow - 1, for: .vertical)
        
        containerStackView.addArrangedSubview(textStackView)
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
        ])
    
        
        nameLabel.isUserInteractionEnabled = false
        usernameLabel.isUserInteractionEnabled = false
        avatarImageView.isUserInteractionEnabled = false
    }
    
}

// MARK: - AvatarStackedImageView
extension UserTableViewCell: AvatarConfigurableView {
    static var configurableAvatarImageSize: CGSize { CGSize(width: 42, height: 42) }
    static var configurableAvatarImageCornerRadius: CGFloat { 4 }
    var configurableAvatarImageView: FLAnimatedImageView? { avatarImageView }
}

extension UserTableViewCell {
    func configure(user: MastodonUser) {
        // avatar
        configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: user.avatarImageURL()))
        // name
        let name = user.displayNameWithFallback
        do {
            let mastodonContent = MastodonContent(content: name, emojis: user.emojiMeta)
            let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
            nameLabel.configure(content: metaContent)
        } catch {
            let metaContent = PlaintextMetaContent(string: name)
            nameLabel.configure(content: metaContent)
        }
        // username
        usernameLabel.text = "@" + user.acct
    }
}
