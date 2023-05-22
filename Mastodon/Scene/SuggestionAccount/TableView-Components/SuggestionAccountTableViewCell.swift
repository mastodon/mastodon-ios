//
//  SuggestionAccountTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/21.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import MetaTextKit
import MastodonMeta
import MastodonAsset
import MastodonLocalization
import MastodonUI
import MastodonCore

protocol SuggestionAccountTableViewCellDelegate: AnyObject, UserViewDelegate {}

final class SuggestionAccountTableViewCell: UITableViewCell {

    static let reuseIdentifier = "SuggestionAccountTableViewCell"

    var disposeBag = Set<AnyCancellable>()
    weak var delegate: SuggestionAccountTableViewCellDelegate?
    
    let userView: UserView
    let bioMetaLabel: MetaLabel
    private let contentStackView: UIStackView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        userView = UserView()
        bioMetaLabel = MetaLabel()
        bioMetaLabel.numberOfLines = 0
        bioMetaLabel.textAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular)),
            .foregroundColor: UIColor.label
        ]
        bioMetaLabel.linkAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold)),
            .foregroundColor: Asset.Colors.brand.color
        ]
        bioMetaLabel.isUserInteractionEnabled = false

        contentStackView = UIStackView(arrangedSubviews: [userView, bioMetaLabel])
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.alignment = .leading
        contentStackView.axis = .vertical

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(contentStackView)

        backgroundColor = .systemBackground

        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("We don't support ancient technology like Storyboards") }

    private func setupConstraints() {
        let constraints = [
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 16),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        disposeBag.removeAll()
    }

    func configure(viewModel: SuggestionAccountTableViewCell.ViewModel) {
        userView.configure(user: viewModel.user, delegate: delegate)

        Publishers.CombineLatest3(
            viewModel.followedUsers,
            viewModel.followRequestedUsers,
            viewModel.blockedUsers
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] followed, requested, blocked in
            
            guard let self else { return }
            
            if blocked.contains(viewModel.user.id) {
                self.userView.setButtonState(.blocked)
            } else if followed.contains(viewModel.user.id) {
                self.userView.setButtonState(.unfollow)
            } else if requested.contains(viewModel.user.id) {
                self.userView.setButtonState(.pending)
            } else if viewModel.user.locked {
                self.userView.setButtonState(.request)
            } else {
                self.userView.setButtonState(.follow)
            }
        }
        .store(in: &disposeBag)
        
        let metaContent: MetaContent = {
            do {
                //TODO: Add emojis
                let mastodonContent = MastodonContent(content: viewModel.user.note ?? "", emojis: [:])
                return try MastodonMetaContent.convert(document: mastodonContent)
            } catch {
                assertionFailure()
                return PlaintextMetaContent(string: viewModel.user.note ?? "")
            }
        }()

        bioMetaLabel.configure(content: metaContent)
    }
}
