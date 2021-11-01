//
//  PickServerTitleCell.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import UIKit

final class PickServerTitleCell: UITableViewCell {
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 34, weight: .bold))
        label.textColor = Asset.Colors.Label.primary.color
        label.text = L10n.Scene.ServerPicker.title
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    var containerHeightLayoutConstraint: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
}

extension PickServerTitleCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = Asset.Theme.Mastodon.systemGroupedBackground.color
        
        let container = UIStackView()
        container.axis = .vertical
        container.translatesAutoresizingMaskIntoConstraints = false
        containerHeightLayoutConstraint = container.heightAnchor.constraint(equalToConstant: .leastNonzeroMagnitude)
        contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        container.addArrangedSubview(titleLabel)
        
        configureTitleLabelDisplay()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        configureTitleLabelDisplay()
    }
}

extension PickServerTitleCell {
    private func configureTitleLabelDisplay() {
        guard traitCollection.userInterfaceIdiom == .pad else {
            titleLabel.isHidden = false
            return
        }
        
        switch traitCollection.horizontalSizeClass {
        case .regular:
            titleLabel.isHidden = true
            containerHeightLayoutConstraint.isActive = true
        default:
            titleLabel.isHidden = false
            containerHeightLayoutConstraint.isActive = false
        }
    }
}
