// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonAsset

class ToggleTableViewCell: UITableViewCell {
    class var reuseIdentifier: String {
        return "ToggleTableViewCell"
    }

    let label: UILabel
    let toggle: UISwitch

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
        label.numberOfLines = 0
        
        toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.onTintColor = Asset.Colors.Brand.blurple.color
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        

        contentView.addSubview(label)
        contentView.addSubview(toggle)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupConstraints() {
        let constraints = [
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 11),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 11),
            
            toggle.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 16),
            toggle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.trailingAnchor.constraint(equalTo: toggle.trailingAnchor, constant: 16)
            
        ]
        NSLayoutConstraint.activate(constraints)
    }
}
