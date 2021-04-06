//
//  SearchingTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/2.
//

import Foundation
import MastodonSDK
import UIKit

final class SearchingTableViewCell: UITableViewCell {
    let _imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .black
        return imageView
    }()
    
    let _titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.buttonDefault.color
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
        selectionStyle = .none
        contentView.addSubview(_imageView)
        _imageView.pin(toSize: CGSize(width: 42, height: 42))
        _imageView.constrain([
            _imageView.constraint(.leading, toView: contentView, constant: 21),
            _imageView.constraint(.centerY, toView: contentView)
        ])
        
        contentView.addSubview(_titleLabel)
        _titleLabel.pin(top: 12, left: 75, bottom: nil, right: 0)
        
        contentView.addSubview(_subTitleLabel)
        _subTitleLabel.pin(top: 34, left: 75, bottom: nil, right: 0)
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
    
    func config(with tag: Mastodon.Entity.Tag) {
        let image = UIImage(systemName: "number.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 34, weight: .regular))!.withRenderingMode(.alwaysTemplate)
        _imageView.image = image
        _titleLabel.text = "# " + tag.name
        guard let historys = tag.history else {
            _subTitleLabel.text = ""
            return
        }
        let recentHistory = historys[0 ... 2]
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
