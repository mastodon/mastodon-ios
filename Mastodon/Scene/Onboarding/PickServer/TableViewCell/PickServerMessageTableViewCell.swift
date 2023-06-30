//
//  PickServerMessageTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-13.
//

import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

public final class PickServerMessageTableViewCell: UITableViewCell {

    let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.textAlignment = .center
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 14, weight: .semibold))
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension PickServerMessageTableViewCell {

    public func _init() {
        selectionStyle = .none
        backgroundColor = .clear

        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        contentView.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor),
            messageLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
        ])
    }

}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct PickServerMessageTableViewCell_Previews: PreviewProvider {

    static var previews: some View {
        UIViewPreview(width: 375) {
            let view = PickServerMessageTableViewCell()
            view.messageLabel.text = "Hello, world!"
            return view
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }

}

#endif
