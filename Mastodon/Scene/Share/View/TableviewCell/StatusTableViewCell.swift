//
//  StatusTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import os.log
import UIKit
import AVKit
import Combine
import CoreData
import CoreDataStack
import ActiveLabel

protocol StatusTableViewCellDelegate: class {
    var context: AppContext! { get }
    var managedObjectContext: NSManagedObjectContext { get }
    
    func parent() -> UIViewController
    var playerViewControllerDelegate: AVPlayerViewControllerDelegate? { get }
    
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, headerInfoLabelDidPressed label: UILabel)
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, avatarButtonDidPressed button: UIButton)
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, revealContentWarningButtonDidPressed button: UIButton)
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, pollVoteButtonPressed button: UIButton)
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity)
    
    func statusTableViewCell(_ cell: StatusTableViewCell, mosaicImageViewContainer: MosaicImageViewContainer, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
    func statusTableViewCell(_ cell: StatusTableViewCell, mosaicImageViewContainer: MosaicImageViewContainer, didTapImageView imageView: UIImageView, atIndex index: Int)
    
    func statusTableViewCell(_ cell: StatusTableViewCell, playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView)
    func statusTableViewCell(_ cell: StatusTableViewCell, playerViewControllerDidPressed playerViewController: AVPlayerViewController)
    
    func statusTableViewCell(_ cell: StatusTableViewCell, actionToolbarContainer: ActionToolbarContainer, replyButtonDidPressed sender: UIButton)
    func statusTableViewCell(_ cell: StatusTableViewCell, actionToolbarContainer: ActionToolbarContainer, reblogButtonDidPressed sender: UIButton)
    func statusTableViewCell(_ cell: StatusTableViewCell, actionToolbarContainer: ActionToolbarContainer, likeButtonDidPressed sender: UIButton)
    
    func statusTableViewCell(_ cell: StatusTableViewCell, pollTableView: PollTableView, didSelectRowAt indexPath: IndexPath)    
}

extension StatusTableViewCellDelegate {
    func statusTableViewCell(_ cell: StatusTableViewCell, playerViewControllerDidPressed playerViewController: AVPlayerViewController) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        playerViewController.showsPlaybackControls.toggle()
    }
}

final class StatusTableViewCell: UITableViewCell {
    
    static let bottomPaddingHeight: CGFloat = 10
    
    weak var delegate: StatusTableViewCellDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    var pollCountdownSubscription: AnyCancellable?
    var observations = Set<NSKeyValueObservation>()
    private var selectionBackgroundViewObservation: NSKeyValueObservation?
    
    let statusView = StatusView()
    let threadMetaStackView = UIStackView()
    let threadMetaView = ThreadMetaView()
    let separatorLine = UIView.separatorLine
    
    var separatorLineToEdgeLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToEdgeTrailingLayoutConstraint: NSLayoutConstraint!
    
    var separatorLineToMarginLeadingLayoutConstraint: NSLayoutConstraint!
    var separatorLineToMarginTrailingLayoutConstraint: NSLayoutConstraint!

    override func prepareForReuse() {
        super.prepareForReuse()
        selectionStyle = .default
        statusView.updateContentWarningDisplay(isHidden: true, animated: false)
        statusView.statusMosaicImageViewContainer.contentWarningOverlayView.isUserInteractionEnabled = true
        statusView.pollTableView.dataSource = nil
        statusView.playerContainerView.reset()
        statusView.playerContainerView.contentWarningOverlayView.isUserInteractionEnabled = true
        statusView.playerContainerView.isHidden = true
        threadMetaView.isHidden = true
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
        
        // precondition: app is active 
        guard UIApplication.shared.applicationState == .active else { return }
        DispatchQueue.main.async {
            self.statusView.drawContentWarningImageView()
        }
    }
    
}

extension StatusTableViewCell {
    
    private func _init() {
        backgroundColor = Asset.Colors.Background.systemBackground.color
        
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            statusView.leadingAnchor.constraint(equalTo:  contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: statusView.trailingAnchor),
        ])
        
        threadMetaStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(threadMetaStackView)
        NSLayoutConstraint.activate([
            threadMetaStackView.topAnchor.constraint(equalTo: statusView.bottomAnchor),
            threadMetaStackView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            threadMetaStackView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            threadMetaStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        threadMetaStackView.addArrangedSubview(threadMetaView)
        
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

        statusView.delegate = self
        statusView.pollTableView.delegate = self
        statusView.statusMosaicImageViewContainer.delegate = self
        statusView.actionToolbarContainer.delegate = self
        
        // default hidden
        threadMetaView.isHidden = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        resetSeparatorLineLayout()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        resetContentOverlayBlurImageBackgroundColor(selected: highlighted)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        resetContentOverlayBlurImageBackgroundColor(selected: selected)
    }
    
}

extension StatusTableViewCell {
    
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
    
    private func resetContentOverlayBlurImageBackgroundColor(selected: Bool) {
        let imageViewBackgroundColor: UIColor? = selected ? selectedBackgroundView?.backgroundColor : backgroundColor
        statusView.contentWarningOverlayView.blurContentImageView.backgroundColor = imageViewBackgroundColor
    }
}

// MARK: - UITableViewDelegate
extension StatusTableViewCell: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if tableView === statusView.pollTableView, let diffableDataSource = statusView.pollTableViewDataSource {
            var pollID: String?
            defer {
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: indexPath: %s. PollID: %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription, pollID ?? "<nil>")
            }
            guard let item = diffableDataSource.itemIdentifier(for: indexPath),
                  case let .opion(objectID, _) = item,
                  let option = delegate?.managedObjectContext.object(with: objectID) as? PollOption else {
                return false
            }
            pollID = option.poll.id
            return !option.poll.expired
        } else {
            assertionFailure()
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView === statusView.pollTableView, let diffableDataSource = statusView.pollTableViewDataSource {
            var pollID: String?
            defer {
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: indexPath: %s. PollID: %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription, pollID ?? "<nil>")
            }

            guard let context = delegate?.context else { return nil }
            guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else { return nil }
            guard let item = diffableDataSource.itemIdentifier(for: indexPath),
                  case let .opion(objectID, _) = item,
                  let option = delegate?.managedObjectContext.object(with: objectID) as? PollOption else {
                return nil
            }
            let poll = option.poll
            pollID = poll.id
            
            // disallow select when: poll expired OR user voted remote OR user voted local
            let userID = activeMastodonAuthenticationBox.userID
            let didVotedRemote = (option.poll.votedBy ?? Set()).contains(where: { $0.id == userID })
            let votedOptions = poll.options.filter { option in
                (option.votedBy ?? Set()).map { $0.id }.contains(userID)
            }
            let didVotedLocal = !votedOptions.isEmpty
            
            if poll.multiple {
                guard !option.poll.expired, !didVotedRemote else {
                    return nil
                }
            } else {
                guard !option.poll.expired, !didVotedRemote, !didVotedLocal else {
                    return nil
                }
            }
            
            return indexPath
        } else {
            assertionFailure()
            return indexPath
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView === statusView.pollTableView {
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: indexPath: %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
            delegate?.statusTableViewCell(self, pollTableView: statusView.pollTableView, didSelectRowAt: indexPath)
        } else {
            assertionFailure()
        }
    }
    
}

// MARK: - StatusViewDelegate
extension StatusTableViewCell: StatusViewDelegate {
    
    func statusView(_ statusView: StatusView, headerInfoLabelDidPressed label: UILabel) {
        delegate?.statusTableViewCell(self, statusView: statusView, headerInfoLabelDidPressed: label)
    }
    
    func statusView(_ statusView: StatusView, avatarButtonDidPressed button: UIButton) {
        delegate?.statusTableViewCell(self, statusView: statusView, avatarButtonDidPressed: button)
    }
    
    func statusView(_ statusView: StatusView, revealContentWarningButtonDidPressed button: UIButton) {
        delegate?.statusTableViewCell(self, statusView: statusView, revealContentWarningButtonDidPressed: button)
    }
    
    func statusView(_ statusView: StatusView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        delegate?.statusTableViewCell(self, statusView: statusView, contentWarningOverlayViewDidPressed: contentWarningOverlayView)
    }
    
    func statusView(_ statusView: StatusView, playerContainerView: PlayerContainerView, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        delegate?.statusTableViewCell(self, playerContainerView: playerContainerView, contentWarningOverlayViewDidPressed: contentWarningOverlayView)
    }
    
    func statusView(_ statusView: StatusView, pollVoteButtonPressed button: UIButton) {
        delegate?.statusTableViewCell(self, statusView: statusView, pollVoteButtonPressed: button)
    }
    
    func statusView(_ statusView: StatusView, activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        delegate?.statusTableViewCell(self, statusView: statusView, activeLabel: activeLabel, didSelectActiveEntity: entity)
    }

}

// MARK: - MosaicImageViewDelegate
extension StatusTableViewCell: MosaicImageViewContainerDelegate {
    
    func mosaicImageViewContainer(_ mosaicImageViewContainer: MosaicImageViewContainer, didTapImageView imageView: UIImageView, atIndex index: Int) {
        delegate?.statusTableViewCell(self, mosaicImageViewContainer: mosaicImageViewContainer, didTapImageView: imageView, atIndex: index)
    }
    
    func mosaicImageViewContainer(_ mosaicImageViewContainer: MosaicImageViewContainer, contentWarningOverlayViewDidPressed contentWarningOverlayView: ContentWarningOverlayView) {
        delegate?.statusTableViewCell(self, mosaicImageViewContainer: mosaicImageViewContainer, contentWarningOverlayViewDidPressed: contentWarningOverlayView)
    }

}

// MARK: - ActionToolbarContainerDelegate
extension StatusTableViewCell: ActionToolbarContainerDelegate {
    
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, replayButtonDidPressed sender: UIButton) {
        delegate?.statusTableViewCell(self, actionToolbarContainer: actionToolbarContainer, replyButtonDidPressed: sender)
    }
    
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, reblogButtonDidPressed sender: UIButton) {
        delegate?.statusTableViewCell(self, actionToolbarContainer: actionToolbarContainer, reblogButtonDidPressed: sender)
    }
    
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, starButtonDidPressed sender: UIButton) {
        delegate?.statusTableViewCell(self, actionToolbarContainer: actionToolbarContainer, likeButtonDidPressed: sender)
    }
    
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, moreButtonDidPressed sender: UIButton) {
        
    }
    
}
