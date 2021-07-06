//
//  SearchingTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/2.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit

final class SearchingTableViewCell: UITableViewCell {
    let _imageView: UIImageView = {
        let imageView = UIImageView()
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        _imageView.af.cancelImageRequest()
        _imageView.image = nil
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

extension SearchingTableViewCell {
    private func configure() {
        let containerStackView = UIStackView()
        containerStackView.axis = .horizontal
        containerStackView.distribution = .fill
        containerStackView.spacing = 12
        containerStackView.layoutMargins = UIEdgeInsets(top: 12, left: 21, bottom: 12, right: 12)
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        _imageView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.addArrangedSubview(_imageView)
        NSLayoutConstraint.activate([
            _imageView.widthAnchor.constraint(equalToConstant: 42),
            _imageView.heightAnchor.constraint(equalToConstant: 42),
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
    }
    
    func config(with account: Mastodon.Entity.Account) {
        _imageView.af.setImage(
            withURL: URL(string: account.avatar)!,
            placeholderImage: UIImage.placeholder(color: .systemFill),
            imageTransition: .crossDissolve(0.2)
        )
        _titleLabel.text = account.displayName.isEmpty ? account.username : account.displayName
        _subTitleLabel.text = account.acct
    }
    
    func config(with account: MastodonUser) {
        _imageView.af.setImage(
            withURL: URL(string: account.avatar)!,
            placeholderImage: UIImage.placeholder(color: .systemFill),
            imageTransition: .crossDissolve(0.2)
        )
        _titleLabel.text = account.displayName.isEmpty ? account.username : account.displayName
        _subTitleLabel.text = account.acct
    }
    
    func config(with tag: Mastodon.Entity.Tag) {
        let image = UIImage(systemName: "number.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 34, weight: .regular))!.withRenderingMode(.alwaysTemplate)
        _imageView.image = image
        _titleLabel.text = "# " + tag.name
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

struct SearchingTableViewCell_Previews: PreviewProvider {
    static var controls: some View {
        Group {
            UIViewPreview {
                let cell = SearchingTableViewCell()
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
