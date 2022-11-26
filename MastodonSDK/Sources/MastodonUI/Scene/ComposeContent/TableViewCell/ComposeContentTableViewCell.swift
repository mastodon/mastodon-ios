//
//  ComposeContentTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-28.
//

import os.log
import UIKit
import UIHostingConfigurationBackport

final class ComposeContentTableViewCell: UITableViewCell {

    let logger = Logger(subsystem: "ComposeContentTableViewCell", category: "View")

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }

}

extension ComposeContentTableViewCell {

    private func _init() {
        selectionStyle = .none
        layer.zPosition = 999
        backgroundColor = .clear
    }

}
