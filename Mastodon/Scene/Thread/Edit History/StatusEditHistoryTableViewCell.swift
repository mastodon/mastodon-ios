// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonUI
import MastodonSDK
import CoreDataStack

class StatusEditHistoryTableViewCell: UITableViewCell {
    static let identifier = "StatusEditHistoryTableViewCell"

    let dateLabel: UILabel
    let statusView: StatusView
    private let grayBackground: UIView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {

        dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        statusView = StatusView()
        statusView.setup(style: .inline)
        statusView.translatesAutoresizingMaskIntoConstraints = false

        grayBackground = UIView()
        grayBackground.translatesAutoresizingMaskIntoConstraints = false
        //FIXME: @zeitschlag Use correct color
        grayBackground.backgroundColor = UIColor(red: 0.961, green: 0.961, blue: 0.976, alpha: 1)
        grayBackground.layer.borderWidth = 1
        grayBackground.layer.borderColor = UIColor(red: 0.82, green: 0.82, blue: 0.871, alpha: 1).cgColor
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

    func configure(status: Status, statusEdit: StatusEdit) {
        dateLabel.text = "\(statusEdit.createdAt)"
        statusView.configure(status: status, statusEdit: statusEdit)
    }
}

