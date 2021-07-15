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
import Nuke

final class SearchResultTableViewCell: UITableViewCell {

    let _imageView: UIImageView = {
        let imageView = FLAnimatedImageView()
        imageView.tintColor = Asset.Colors.Label.primary.color
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let _titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.brandBlue.color
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
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
        Nuke.cancelRequest(for: _imageView)
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
        
        _imageView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(_imageView)
        NSLayoutConstraint.activate([
            _imageView.widthAnchor.constraint(equalToConstant: 42).priority(.required - 1),
            _imageView.heightAnchor.constraint(equalToConstant: 42).priority(.required - 1),
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
        Nuke.loadImage(
            with: account.avatarImageURL(),
            options: ImageLoadingOptions(
                placeholder: UIImage.placeholder(color: .systemFill),
                transition: .fadeIn(duration: 0.2)
            ),
            into: _imageView
        )
        _titleLabel.text = account.displayName.isEmpty ? account.username : account.displayName
        _subTitleLabel.text = account.acct
    }
    
    func config(with account: MastodonUser) {
        Nuke.loadImage(
            with: account.avatarImageURL(),
            options: ImageLoadingOptions(
                placeholder: UIImage.placeholder(color: .systemFill),
                transition: .fadeIn(duration: 0.2)
            ),
            into: _imageView
        )
        _titleLabel.text = account.displayNameWithFallback
        _subTitleLabel.text = account.acct
    }
    
    func config(with tag: Mastodon.Entity.Tag) {
        let image = UIImage(systemName: "number.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 34, weight: .regular))!.withRenderingMode(.alwaysTemplate)
        _imageView.image = image
        _titleLabel.text = "#" + tag.name
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
        let image = UIImage(systemName: "number.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 34, weight: .regular))!.withRenderingMode(.alwaysTemplate)
        _imageView.image = image
        _titleLabel.text = "# " + tag.name
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

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SearchResultTableViewCell_Previews: PreviewProvider {
    static var controls: some View {
        Group {
            UIViewPreview {
                let cell = SearchResultTableViewCell()
                cell.backgroundColor = .white
                cell._imageView.image = UIImage(systemName: "number.circle.fill")
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
