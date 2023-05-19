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

protocol SuggestionAccountTableViewCellDelegate: AnyObject {
    func suggestionAccountTableViewCell(_ cell: SuggestionAccountTableViewCell, friendshipDidPressed button: UIButton)
}

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

    //MARK: - Action

    @objc private func buttonDidPressed(_ sender: UIButton) {
        delegate?.suggestionAccountTableViewCell(self, friendshipDidPressed: sender)
    }
}
