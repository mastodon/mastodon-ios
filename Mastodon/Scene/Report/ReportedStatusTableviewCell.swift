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
import Meta
import MetaTextView

final class ReportedStatusTableViewCell: UITableViewCell, StatusCell {
    
    static let bottomPaddingHeight: CGFloat = 10
    
    weak var dependency: ReportViewController?
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
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
        statusView.updateContentWarningDisplay(isHidden: true, animated: false)
        statusView.statusMosaicImageViewContainer.contentWarningOverlayView.isUserInteractionEnabled = true
        statusView.pollTableView.dataSource = nil
        statusView.playerContainerView.reset()
        statusView.playerContainerView.contentWarningOverlayView.isUserInteractionEnabled = true
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
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            checkbox.image = UIImage(systemName: "checkmark.circle.fill")
            checkbox.tintColor = Asset.Colors.brandBlue.color
        } else if !isSelected {
            checkbox.image = UIImage(systemName: "circle")
            checkbox.tintColor = Asset.Colors.Label.secondary.color
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if isSelected {
            checkbox.image = UIImage(systemName: "checkmark.circle.fill")
        } else {
            checkbox.image = UIImage(systemName: "circle")
        }
        checkbox.tintColor = Asset.Colors.Label.secondary.color
    }
}

extension ReportedStatusTableViewCell {
    
    private func _init() {
        backgroundColor = Asset.Colors.Background.secondaryGroupedSystemBackground.color
        
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
        statusView.delegate = self
        statusView.statusMosaicImageViewContainer.delegate = self
        statusView.actionToolbarContainer.isHidden = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        resetSeparatorLineLayout()
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

extension ReportedStatusTableViewCell: MosaicImageViewContainerDelegate {
    func mosaicImageViewContainer(_ mosaicImageViewContainer: MosaicImageViewContainer, didTapImageView imageView: UIImageView, atIndex index: Int) {
        
    }
    
    func mosaicImageViewContainer(_ mosaicImageViewContainer: MosaicImageViewContainer, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        
        guard let dependency = self.dependency else { return }
        StatusProviderFacade.responseToStatusContentWarningRevealAction(dependency: dependency, cell: self)
    }
}

extension ReportedStatusTableViewCell: StatusViewDelegate {

    func statusView(_ statusView: StatusView, headerInfoLabelDidPressed label: UILabel) {
    }

    func statusView(_ statusView: StatusView, avatarImageViewDidPressed imageView: UIImageView) {
    }

    func statusView(_ statusView: StatusView, revealContentWarningButtonDidPressed button: UIButton) {
        guard let dependency = self.dependency else { return }
        StatusProviderFacade.responseToStatusContentWarningRevealAction(dependency: dependency, cell: self)
    }
    
    func statusView(_ statusView: StatusView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        guard let dependency = self.dependency else { return }
        StatusProviderFacade.responseToStatusContentWarningRevealAction(dependency: dependency, cell: self)
    }
    
    func statusView(_ statusView: StatusView, playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        guard let dependency = self.dependency else { return }
        StatusProviderFacade.responseToStatusContentWarningRevealAction(dependency: dependency, cell: self)
    }
    
    func statusView(_ statusView: StatusView, pollVoteButtonPressed button: UIButton) {
    }
    
    func statusView(_ statusView: StatusView, activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
    }

    func statusView(_ statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta) {
    }

}
