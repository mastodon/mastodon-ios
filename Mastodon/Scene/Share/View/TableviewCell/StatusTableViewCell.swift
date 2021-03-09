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

protocol StatusTableViewCellDelegate: class {
    var context: AppContext! { get }
    var managedObjectContext: NSManagedObjectContext { get }
    
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, contentWarningActionButtonPressed button: UIButton)
    func statusTableViewCell(_ cell: StatusTableViewCell, mosaicImageViewContainer: MosaicImageViewContainer, didTapContentWarningVisualEffectView visualEffectView: UIVisualEffectView)
    func statusTableViewCell(_ cell: StatusTableViewCell, mosaicImageViewContainer: MosaicImageViewContainer, didTapImageView imageView: UIImageView, atIndex index: Int)
    func statusTableViewCell(_ cell: StatusTableViewCell, actionToolbarContainer: ActionToolbarContainer, boostButtonDidPressed sender: UIButton)
    func statusTableViewCell(_ cell: StatusTableViewCell, actionToolbarContainer: ActionToolbarContainer, likeButtonDidPressed sender: UIButton)
    
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, pollVoteButtonPressed button: UIButton)
    func statusTableViewCell(_ cell: StatusTableViewCell, pollTableView: PollTableView, didSelectRowAt indexPath: IndexPath)
}

final class StatusTableViewCell: UITableViewCell {
    
    static let bottomPaddingHeight: CGFloat = 10
    
    weak var delegate: StatusTableViewCellDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    var pollCountdownSubscription: AnyCancellable?
    var observations = Set<NSKeyValueObservation>()
    
    let statusView = StatusView()
        
    override func prepareForReuse() {
        super.prepareForReuse()
        statusView.isStatusTextSensitive = false
        statusView.cleanUpContentWarning()
        statusView.pollTableView.dataSource = nil
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
    
}

extension StatusTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = Asset.Colors.Background.secondaryGroupedSystemBackground.color
        statusView.contentWarningBlurContentImageView.backgroundColor = Asset.Colors.Background.secondaryGroupedSystemBackground.color
        
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            statusView.leadingAnchor.constraint(equalTo:  contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: statusView.trailingAnchor),
        ])
        
        let bottomPaddingView = UIView()
        bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomPaddingView)
        NSLayoutConstraint.activate([
            bottomPaddingView.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 10),
            bottomPaddingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomPaddingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomPaddingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomPaddingView.heightAnchor.constraint(equalToConstant: StatusTableViewCell.bottomPaddingHeight).priority(.defaultHigh),
        ])
        bottomPaddingView.backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
                
        statusView.delegate = self
        statusView.pollTableView.delegate = self
        statusView.statusMosaicImageViewContainer.delegate = self
        statusView.actionToolbarContainer.delegate = self
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
    
    func statusView(_ statusView: StatusView, contentWarningActionButtonPressed button: UIButton) {
        delegate?.statusTableViewCell(self, statusView: statusView, contentWarningActionButtonPressed: button)
    }
    
    func statusView(_ statusView: StatusView, pollVoteButtonPressed button: UIButton) {
        delegate?.statusTableViewCell(self, statusView: statusView, pollVoteButtonPressed: button)
    }
    
}

// MARK: - MosaicImageViewDelegate
extension StatusTableViewCell: MosaicImageViewContainerDelegate {
    
    func mosaicImageViewContainer(_ mosaicImageViewContainer: MosaicImageViewContainer, didTapImageView imageView: UIImageView, atIndex index: Int) {
        delegate?.statusTableViewCell(self, mosaicImageViewContainer: mosaicImageViewContainer, didTapImageView: imageView, atIndex: index)
    }
    
    func mosaicImageViewContainer(_ mosaicImageViewContainer: MosaicImageViewContainer, didTapContentWarningVisualEffectView visualEffectView: UIVisualEffectView) {
        delegate?.statusTableViewCell(self, mosaicImageViewContainer: mosaicImageViewContainer, didTapContentWarningVisualEffectView: visualEffectView)
    }

}

// MARK: - ActionToolbarContainerDelegate
extension StatusTableViewCell: ActionToolbarContainerDelegate {
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, replayButtonDidPressed sender: UIButton) {
        
    }
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, boostButtonDidPressed sender: UIButton) {
        delegate?.statusTableViewCell(self, actionToolbarContainer: actionToolbarContainer, boostButtonDidPressed: sender)
    }
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, starButtonDidPressed sender: UIButton) {
        delegate?.statusTableViewCell(self, actionToolbarContainer: actionToolbarContainer, likeButtonDidPressed: sender)
    }
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, bookmarkButtonDidPressed sender: UIButton) {
        
    }
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, moreButtonDidPressed sender: UIButton) {
        
    }
}
