//
//  UserTableViewCell.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import UIKit
import Combine
import CoreDataStack
import MastodonAsset
import MastodonLocalization
import MastodonUI
import MastodonSDK

protocol UserTableViewCellDelegate: UserViewDelegate, AnyObject { }

final class UserTableViewCell: UITableViewCell {

    static let reuseIdentifier = "UserTableViewCell"
    weak var delegate: UserTableViewCellDelegate?
    
    let userView = UserView()
    
    let separatorLine = UIView.separatorLine
    
    var disposeBag = Set<AnyCancellable>()

    override func prepareForReuse() {
        super.prepareForReuse()
        
        delegate = nil
        disposeBag = Set<AnyCancellable>()
        userView.prepareForReuse()
    }
    
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
        userView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(userView)
        NSLayoutConstraint.activate([
            userView.topAnchor.constraint(equalTo: contentView.topAnchor),
            userView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            userView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            userView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)).priority(.required - 1),
        ])

        userView.accessibilityTraits.insert(.button)
    }
    
}
