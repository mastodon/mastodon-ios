//
//  ReportStatusTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-7.
//

import UIKit
import Combine
import MastodonUI
import MastodonAsset

final class ReportStatusTableViewCell: UITableViewCell {
    
    static let checkboxLeadingMargin: CGFloat = 16
    static let checkboxSize = CGSize(width: 32, height: 32)
    static let statusViewLeadingSpacing: CGFloat = 22
    
    var disposeBag = Set<AnyCancellable>()
    
    let checkbox: UIImageView = {
        let imageView = UIImageView()
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
        imageView.tintColor = Asset.Colors.Label.secondary.color
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let statusView = StatusView()
    
    let separatorLine = UIView.separatorLine
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
        statusView.prepareForReuse()
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

extension ReportStatusTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkbox)
        NSLayoutConstraint.activate([
            checkbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ReportStatusTableViewCell.checkboxLeadingMargin),
            checkbox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkbox.heightAnchor.constraint(equalToConstant: ReportStatusTableViewCell.checkboxSize.width).priority(.required - 1),
            checkbox.widthAnchor.constraint(equalToConstant: ReportStatusTableViewCell.checkboxSize.height).priority(.required - 1),
        ])
        
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            statusView.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: ReportStatusTableViewCell.statusViewLeadingSpacing),
            statusView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 24),
        ])
        statusView.setup(style: .report)
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)).priority(.required - 1),
        ])
        
        statusView.isUserInteractionEnabled = false
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            checkbox.image = UIImage(systemName: "checkmark.square.fill")
            checkbox.tintColor = Asset.Colors.Label.primary.color
        } else {
            checkbox.image = UIImage(systemName: "square")
            checkbox.tintColor = Asset.Colors.Label.secondary.color
        }
    }
    
}
