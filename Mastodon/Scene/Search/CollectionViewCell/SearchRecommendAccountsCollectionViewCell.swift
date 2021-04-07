//
//  SearchRecommendAccountsCollectionViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/1.
//

import Foundation
import MastodonSDK
import UIKit

class SearchRecommendAccountsCollectionViewCell: UICollectionViewCell {
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let displayNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let acctLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let followButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.white, for: .normal)
        button.setTitle(L10n.Scene.Search.Recommend.Accounts.follow, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        headerImageView.af.cancelImageRequest()
        avatarImageView.af.cancelImageRequest()
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

extension SearchRecommendAccountsCollectionViewCell {
    private func configure() {
        headerImageView.backgroundColor = Asset.Colors.brandBlue.color
        layer.cornerRadius = 8
        clipsToBounds = true
        
        contentView.addSubview(headerImageView)
        headerImageView.pin(top: 16, left: 0, bottom: 0, right: 0)
        
        contentView.addSubview(avatarImageView)
        avatarImageView.pin(toSize: CGSize(width: 88, height: 88))
        avatarImageView.constrain([
            avatarImageView.constraint(.top, toView: contentView),
            avatarImageView.constraint(.centerX, toView: contentView)
        ])
        
        contentView.addSubview(displayNameLabel)
        displayNameLabel.constrain([
            displayNameLabel.constraint(.top, toView: contentView, constant: 108),
            displayNameLabel.constraint(.centerX, toView: contentView)
        ])
        
        contentView.addSubview(acctLabel)
        acctLabel.constrain([
            acctLabel.constraint(.top, toView: contentView, constant: 132),
            acctLabel.constraint(.centerX, toView: contentView)
        ])
        
        contentView.addSubview(followButton)
        followButton.pin(toSize: CGSize(width: 76, height: 24))
        followButton.constrain([
            followButton.constraint(.top, toView: contentView, constant: 159),
            followButton.constraint(.centerX, toView: contentView)
        ])
    }
    
    func config(with account: Mastodon.Entity.Account) {
        displayNameLabel.text = account.displayName.isEmpty ? account.username : account.displayName
        acctLabel.text = account.acct
        avatarImageView.af.setImage(
            withURL: URL(string: account.avatar)!,
            placeholderImage: UIImage.placeholder(color: .systemFill),
            imageTransition: .crossDissolve(0.2)
        )
        headerImageView.af.setImage(
            withURL: URL(string: account.header)!,
            placeholderImage: UIImage.placeholder(color: .systemFill),
            imageTransition: .crossDissolve(0.2)
        )
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SearchRecommendAccountsCollectionViewCell_Previews: PreviewProvider {
    static var controls: some View {
        Group {
            UIViewPreview {
                let cell = SearchRecommendAccountsCollectionViewCell()
                cell.avatarImageView.backgroundColor = .white
                cell.headerImageView.backgroundColor = .red
                cell.displayNameLabel.text = "sunxiaojian"
                cell.acctLabel.text = "sunxiaojian@mastodon.online"
                return cell
            }
            .previewLayout(.fixed(width: 257, height: 202))
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
