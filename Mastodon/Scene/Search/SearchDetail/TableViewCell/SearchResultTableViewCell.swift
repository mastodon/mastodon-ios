//
//  SearchResultTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/2.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import FLAnimatedImage
import MetaTextKit
import MastodonMeta

final class SearchResultTableViewCell: UITableViewCell {

    let avatarImageView: AvatarImageView = {
        let imageView = AvatarImageView()
        imageView.tintColor = Asset.Colors.Label.primary.color
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let hashtagImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "number.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 34, weight: .regular))!.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Asset.Colors.Label.primary.color
        return imageView
    }()
    
    let _titleLabel = MetaLabel(style: .statusName)
    
    let _subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }()

    let separatorLine = UIView.separatorLine

    var separatorLineToEdgeLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToEdgeTrailingLayoutConstraint: NSLayoutConstraint!

    var separatorLineToMarginLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToMarginTrailingLayoutConstraint: NSLayoutConstraint!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.af.cancelImageRequest()
        setDisplayAvatarImage()
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

extension SearchResultTableViewCell {
    private func configure() {
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
        
        hashtagImageView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addSubview(hashtagImageView)
        NSLayoutConstraint.activate([
            hashtagImageView.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            hashtagImageView.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            hashtagImageView.widthAnchor.constraint(equalToConstant: 42).priority(.required - 1),
            hashtagImageView.heightAnchor.constraint(equalToConstant: 42).priority(.required - 1),
        ])
        
        let textStackView = UIStackView()
        textStackView.axis = .vertical
        textStackView.distribution = .fill
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        _titleLabel.translatesAutoresizingMaskIntoConstraints = false
        textStackView.addArrangedSubview(_titleLabel)
        _subTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        textStackView.addArrangedSubview(_subTitleLabel)
        _subTitleLabel.setContentHuggingPriority(.defaultLow - 1, for: .vertical)
        
        containerStackView.addArrangedSubview(textStackView)

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
        
        _titleLabel.isUserInteractionEnabled = false
        _subTitleLabel.isUserInteractionEnabled = false
        avatarImageView.isUserInteractionEnabled = false
        
        setDisplayAvatarImage()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        resetSeparatorLineLayout()
    }

}

extension SearchResultTableViewCell {

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

extension SearchResultTableViewCell {
    
    func config(with account: Mastodon.Entity.Account) {
        configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: account.avatarImageURL()))
        let name = account.displayName.isEmpty ? account.username : account.displayName
        do {
            let mastodonContent = MastodonContent(content: name, emojis: account.emojiMeta)
            let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
            _titleLabel.configure(content: metaContent)
        } catch {
            let metaContent = PlaintextMetaContent(string: name)
            _titleLabel.configure(content: metaContent)
        }
        _subTitleLabel.text = "@" + account.acct
    }
    
    func config(with account: MastodonUser) {
        configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: account.avatarImageURL()))
        do {
            let mastodonContent = MastodonContent(content: account.displayNameWithFallback, emojis: account.emojiMeta)
            let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
            _titleLabel.configure(content: metaContent)
        } catch {
            let metaContent = PlaintextMetaContent(string: account.displayNameWithFallback)
            _titleLabel.configure(content: metaContent)
        }
        _subTitleLabel.text = "@" + account.acct
    }
    
    func config(with tag: Mastodon.Entity.Tag) {
        configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: nil))
        setDisplayHashtagImage()
        let metaContent = PlaintextMetaContent(string: "#" + tag.name)
        _titleLabel.configure(content: metaContent)
        guard let histories = tag.history else {
            _subTitleLabel.text = ""
            return
        }
        let recentHistory = histories.prefix(2)
        let peopleAreTalking = recentHistory.compactMap { Int($0.accounts) }.reduce(0, +)
        let string = L10n.Scene.Search.Recommend.HashTag.peopleTalking(String(peopleAreTalking))
        _subTitleLabel.text = string
    }

    func config(with tag: Tag) {
        configure(with: AvatarConfigurableViewConfiguration(avatarImageURL: nil))
        setDisplayHashtagImage()
        let metaContent = PlaintextMetaContent(string: "#" + tag.name)
        _titleLabel.configure(content: metaContent)
        guard let histories = tag.histories?.sorted(by: {
            $0.createAt.compare($1.createAt) == .orderedAscending
        }) else {
            _subTitleLabel.text = ""
            return
        }
        let recentHistory = histories.prefix(2)
        let peopleAreTalking = recentHistory.compactMap { Int($0.accounts) }.reduce(0, +)
        let string = L10n.Scene.Search.Recommend.HashTag.peopleTalking(String(peopleAreTalking))
        _subTitleLabel.text = string
    }
}

extension SearchResultTableViewCell {
    func setDisplayAvatarImage() {
        avatarImageView.alpha = 1
        hashtagImageView.alpha = 0
    }
    
    func setDisplayHashtagImage() {
        avatarImageView.alpha = 0
        hashtagImageView.alpha = 1
    }
}

// MARK: - AvatarStackedImageView
extension SearchResultTableViewCell: AvatarConfigurableView {
    static var configurableAvatarImageSize: CGSize { CGSize(width: 42, height: 42) }
    static var configurableAvatarImageCornerRadius: CGFloat { 4 }
    var configurableAvatarImageView: FLAnimatedImageView? { avatarImageView }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SearchResultTableViewCell_Previews: PreviewProvider {
    static var controls: some View {
        Group {
            UIViewPreview {
                let cell = SearchResultTableViewCell()
                cell.backgroundColor = .white
                cell.setDisplayHashtagImage()
                cell._titleLabel.text = "Electronic Frontier Foundation"
                cell._subTitleLabel.text = "@eff@mastodon.social"
                return cell
            }
            .previewLayout(.fixed(width: 228, height: 130))
        }
    }
    
    static var previews: some View {
        Group {
            controls.colorScheme(.light)
            controls.colorScheme(.dark)
        }
        .background(Color.gray)
    }
}

#endif
