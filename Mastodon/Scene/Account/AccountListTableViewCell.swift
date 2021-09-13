//
//  AccountListTableViewCell.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-13.
//


#if DEBUG
import UIKit

final class AccountListTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

}

extension AccountListTableViewCell {

    private func _init() {

    }

}

#endif
