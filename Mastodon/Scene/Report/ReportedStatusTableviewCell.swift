//
//  ReportedStatusTableViewCell.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/20.
//

import os.log
import UIKit
import AVKit
import Combine
import CoreData
import CoreDataStack
import ActiveLabel

protocol ReportedStatusTableViewCellDelegate: class {
    func reportedStatus(cell: ReportedStatusTableViewCell, isSelected indexPath: IndexPath) -> Bool
}

final class ReportedStatusTableViewCell: UITableViewCell, StatusCell {
    
    static let bottomPaddingHeight: CGFloat = 10
    
    weak var delegate: ReportedStatusTableViewCellDelegate?
    var disposeBag = Set<AnyCancellable>()
    var pollCountdownSubscription: AnyCancellable?
    var observations = Set<NSKeyValueObservation>()
    var checked: Bool = false
    
    let statusView = StatusView()
    let separatorLine = UIView.separatorLine
    
    let checkbox: UIImageView = {
        let imageView = UIImageView()
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
        imageView.tintColor = Asset.Colors.Label.secondary.color
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    var separatorLineToEdgeLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToEdgeTrailingLayoutConstraint: NSLayoutConstraint!
    
    var separatorLineToMarginLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToMarginTrailingLayoutConstraint: NSLayoutConstraint!

    override func prepareForReuse() {
        super.prepareForReuse()
        checked = false
        statusView.isStatusTextSensitive = false
        statusView.cleanUpContentWarning()
        statusView.pollTableView.dataSource = nil
        statusView.playerContainerView.reset()
        statusView.playerContainerView.isHidden = true
        disposeBag.removeAll()
        observations.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async {
            self.statusView.drawContentWarningImageView()
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            checkbox.image = UIImage(systemName: "checkmark.circle.fill")
            checkbox.tintColor = Asset.Colors.Label.highlight.color
        } else if !checked {
            checkbox.image = UIImage(systemName: "circle")
            checkbox.tintColor = Asset.Colors.Label.secondary.color
        }
    }
}

extension ReportedStatusTableViewCell {
    
    private func _init() {
        backgroundColor = Asset.Colors.Background.systemBackground.color
        statusView.contentWarningBlurContentImageView.backgroundColor = Asset.Colors.Background.systemBackground.color
        
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkbox)
        NSLayoutConstraint.activate([
            checkbox.widthAnchor.constraint(equalToConstant: 23),
            checkbox.heightAnchor.constraint(equalToConstant: 22),
            checkbox.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor, constant: 12),
            checkbox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            statusView.leadingAnchor.constraint(equalTo:  checkbox.trailingAnchor, constant: 20),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: statusView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 20),
        ])
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        separatorLineToEdgeLeadingLayoutConstraint = separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        separatorLineToEdgeTrailingLayoutConstraint = separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        separatorLineToMarginLeadingLayoutConstraint = separatorLine.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor)
        separatorLineToMarginTrailingLayoutConstraint = separatorLine.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor)
        NSLayoutConstraint.activate([
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)),
        ])
        resetSeparatorLineLayout()

        selectionStyle = .none
        statusView.actionToolbarContainer.isHidden = true
        statusView.isUserInteractionEnabled = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        resetSeparatorLineLayout()
    }
    
    func setupSelected(_ selected: Bool) {
        checked = selected
        if selected {
            checkbox.image = UIImage(systemName: "checkmark.circle.fill")
        } else {
            checkbox.image = UIImage(systemName: "circle")
        }
        checkbox.tintColor = Asset.Colors.Label.secondary.color
    }
}

extension ReportedStatusTableViewCell {
    private func resetSeparatorLineLayout() {
        separatorLineToEdgeLeadingLayoutConstraint.isActive = false
        separatorLineToEdgeTrailingLayoutConstraint.isActive = false
        separatorLineToMarginLeadingLayoutConstraint.isActive = false
        separatorLineToMarginTrailingLayoutConstraint.isActive = false
        
        if traitCollection.userInterfaceIdiom == .phone {
            // to edge
            NSLayoutConstraint.activate([
                separatorLineToEdgeLeadingLayoutConstraint,
                separatorLineToEdgeTrailingLayoutConstraint,
            ])
        } else {
            if traitCollection.horizontalSizeClass == .compact {
                // to edge
                NSLayoutConstraint.activate([
                    separatorLineToEdgeLeadingLayoutConstraint,
                    separatorLineToEdgeTrailingLayoutConstraint,
                ])
            } else {
                // to margin
                NSLayoutConstraint.activate([
                    separatorLineToMarginLeadingLayoutConstraint,
                    separatorLineToMarginTrailingLayoutConstraint,
                ])
            }
        }
    }
}
