// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonUI
import MastodonSDK
import CoreDataStack
import MastodonAsset

class StatusEditHistoryTableViewCell: UITableViewCell {
    static let identifier = "StatusEditHistoryTableViewCell"

    let dateLabel: UILabel
    let statusView: StatusView
    private let grayBackground: UIView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {


        dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.textColor = Asset.Colors.Label.secondary.color
        dateLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))

        statusView = StatusView()
        statusView.setup(style: .inline)
        statusView.translatesAutoresizingMaskIntoConstraints = false

        grayBackground = UIView()
        grayBackground.translatesAutoresizingMaskIntoConstraints = false
        grayBackground.backgroundColor = Asset.Scene.EditHistory.statusBackground.color
        grayBackground.layer.borderWidth = 1
        grayBackground.layer.borderColor = Asset.Scene.EditHistory.statusBackgroundBorder.color.cgColor
        grayBackground.applyCornerRadius(radius: 8)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        grayBackground.addSubview(statusView)
        contentView.addSubview(dateLabel)
        contentView.addSubview(grayBackground)

        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: dateLabel.trailingAnchor, constant: 16),

            grayBackground.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 12),
            grayBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: grayBackground.trailingAnchor, constant: 16),
            contentView.bottomAnchor.constraint(equalTo: grayBackground.bottomAnchor, constant: 16),

            statusView.topAnchor.constraint(equalTo: grayBackground.topAnchor, constant: 12),
            statusView.leadingAnchor.constraint(equalTo: grayBackground.leadingAnchor),
            grayBackground.trailingAnchor.constraint(equalTo: statusView.trailingAnchor),
            grayBackground.bottomAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 12),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func configure(status: Status, statusEdit: StatusEdit, dateText: String) {
        dateLabel.text = dateText
        statusView.configure(status: status, statusEdit: statusEdit)
    }
}

