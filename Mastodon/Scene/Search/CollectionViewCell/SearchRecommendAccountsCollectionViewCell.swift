//
//  SearchRecommendAccountsCollectionViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/1.
//

import Foundation
import MastodonSDK
import UIKit
import CoreDataStack
import Combine

class SearchRecommendAccountsCollectionViewCell: UICollectionViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8.4
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = Asset.Colors.Border.searchCard.color.cgColor
        return imageView
    }()
    
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    
    let displayNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let acctLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let followButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(.white, for: .normal)
        button.setTitle(L10n.Scene.Search.Recommend.Accounts.follow, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        headerImageView.af.cancelImageRequest()
        avatarImageView.af.cancelImageRequest()
        visualEffectView.removeFromSuperview()
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
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        headerImageView.layer.borderColor = Asset.Colors.Border.searchCard.color.cgColor
        applyShadow(color: Asset.Colors.Shadow.searchCard.color, alpha: 0.1, x: 0, y: 3, blur: 12, spread: 0)
    }
    
    private func configure() {
        headerImageView.backgroundColor = Asset.Colors.brandBlue.color
        layer.cornerRadius = 10
        clipsToBounds = false
        applyShadow(color: Asset.Colors.Shadow.searchCard.color, alpha: 0.1, x: 0, y: 3, blur: 12, spread: 0)
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
            displayNameLabel.constraint(.leading, toView: contentView),
            displayNameLabel.constraint(.trailing, toView: contentView),
            displayNameLabel.constraint(.centerX, toView: contentView)
        ])
        
        contentView.addSubview(acctLabel)
        acctLabel.constrain([
            acctLabel.constraint(.top, toView: contentView, constant: 132),
            acctLabel.constraint(.leading, toView: contentView),
            acctLabel.constraint(.trailing, toView: contentView),
            acctLabel.constraint(.centerX, toView: contentView)
        ])
        
        contentView.addSubview(followButton)
        followButton.pin(toSize: CGSize(width: 76, height: 24))
        followButton.constrain([
            followButton.constraint(.top, toView: contentView, constant: 159),
            followButton.constraint(.centerX, toView: contentView)
        ])
    }
    
    func config(with mastodonUser: MastodonUser) {
        displayNameLabel.text = mastodonUser.displayName.isEmpty ? mastodonUser.username : mastodonUser.displayName
        acctLabel.text = mastodonUser.acct
        avatarImageView.af.setImage(
            withURL: URL(string: mastodonUser.avatar)!,
            placeholderImage: UIImage.placeholder(color: .systemFill),
            imageTransition: .crossDissolve(0.2)
        )
        headerImageView.af.setImage(
            withURL: URL(string: mastodonUser.header)!,
            placeholderImage: UIImage.placeholder(color: .systemFill),
            imageTransition: .crossDissolve(0.2)) { [weak self] _ in
            guard let self = self else { return }
            self.headerImageView.addSubview(self.visualEffectView)
            self.visualEffectView.pin(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    func configFollowButton(with mastodonUser: MastodonUser, currentMastodonUser: MastodonUser) {
        self._configFollowButton(with: mastodonUser, currentMastodonUser: currentMastodonUser)
        ManagedObjectObserver.observe(object: currentMastodonUser)
            .sink { _ in
                
            } receiveValue: { change in
                guard case .update(let object) = change.changeType,
                      let newUser = object as? MastodonUser else { return }
                self._configFollowButton(with: mastodonUser, currentMastodonUser: newUser)
            }
            .store(in: &disposeBag)
    }
    
    func _configFollowButton(with mastodonUser: MastodonUser, currentMastodonUser: MastodonUser) {
        var relationshipActionSet = ProfileViewModel.RelationshipActionOptionSet([.follow])

        let isFollowing = mastodonUser.followingBy.flatMap { $0.contains(currentMastodonUser) } ?? false
        if isFollowing {
            relationshipActionSet.insert(.following)
        }

        let isPending = mastodonUser.followRequestedBy.flatMap { $0.contains(currentMastodonUser) } ?? false
        if isPending {
            relationshipActionSet.insert(.pending)
        }

        let isBlocking = mastodonUser.blockingBy.flatMap { $0.contains(currentMastodonUser) } ?? false
        if isBlocking {
            relationshipActionSet.insert(.blocking)
        }

        let isBlockedBy = currentMastodonUser.blockingBy.flatMap { $0.contains(mastodonUser) } ?? false
        if isBlockedBy {
            relationshipActionSet.insert(.blocked)
        }
        self.followButton.setTitle(relationshipActionSet.title, for: .normal)
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
