//
//  StatusViewTableViewCellDelegate.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-13.
//

import UIKit
import MetaTextKit
import MastodonUI
import MastodonSDK

// sourcery: protocolName = "StatusViewDelegate"
// sourcery: replaceOf = "statusView(statusView"
// sourcery: replaceWith = "delegate?.tableViewCell(self, statusView: statusView"
protocol StatusViewContainerTableViewCell: UITableViewCell, AutoGenerateProtocolRelayDelegate {
    var delegate: StatusTableViewCellDelegate? { get }
    var statusView: StatusView { get }
}

// MARK: - AutoGenerateProtocolDelegate
// sourcery: protocolName = "StatusViewDelegate"
// sourcery: replaceOf = "statusView(_"
// sourcery: replaceWith = "func tableViewCell(_ cell: UITableViewCell,"
protocol StatusTableViewCellDelegate: AnyObject, AutoGenerateProtocolDelegate {
    // sourcery:inline:StatusTableViewCellDelegate.AutoGenerateProtocolDelegate
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, headerDidPressed header: UIView)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, contentSensitiveeToggleButtonDidPressed button: UIButton)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, didTapCardWithURL url: URL)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, mediaGridContainerView: MediaGridContainerView, mediaView: MediaView, didSelectMediaViewAt index: Int)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, pollTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, pollVoteButtonPressed button: UIButton)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, actionToolbarContainer: ActionToolbarContainer, buttonDidPressed button: UIButton, action: ActionToolbarContainer.Action)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, menuButton button: UIButton, didSelectAction action: MastodonMenu.Action)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, spoilerOverlayViewDidPressed overlayView: SpoilerOverlayView)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, mediaGridContainerView: MediaGridContainerView, mediaSensitiveButtonDidPressed button: UIButton)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, statusMetricView: StatusMetricView, reblogButtonDidPressed button: UIButton)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, statusMetricView: StatusMetricView, favoriteButtonDidPressed button: UIButton)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, statusMetricView: StatusMetricView, showEditHistory button: UIButton)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, cardControl: StatusCardControl, didTapURL url: URL)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, cardControl: StatusCardControl, didTapProfile account: Mastodon.Entity.Account)
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, cardControlMenu: StatusCardControl) -> [LabeledAction]?
    func tableViewCell(_ cell: UITableViewCell, statusView: StatusView, accessibilityActivate: Void)
    // sourcery:end
}


// MARK: - AutoGenerateProtocolDelegate
// Protocol Extension
extension StatusViewDelegate where Self: StatusViewContainerTableViewCell {
    // sourcery:inline:StatusViewContainerTableViewCell.AutoGenerateProtocolRelayDelegate
    func statusView(_ statusView: StatusView, headerDidPressed header: UIView) {
        delegate?.tableViewCell(self, statusView: statusView, headerDidPressed: header)
    }

    func statusView(_ statusView: StatusView, authorAvatarButtonDidPressed button: AvatarButton) {
        delegate?.tableViewCell(self, statusView: statusView, authorAvatarButtonDidPressed: button)
    }

    func statusView(_ statusView: StatusView, contentSensitiveeToggleButtonDidPressed button: UIButton) {
        delegate?.tableViewCell(self, statusView: statusView, contentSensitiveeToggleButtonDidPressed: button)
    }

    func statusView(_ statusView: StatusView, metaText: MetaText, didSelectMeta meta: Meta) {
        delegate?.tableViewCell(self, statusView: statusView, metaText: metaText, didSelectMeta: meta)
    }

    func statusView(_ statusView: StatusView, didTapCardWithURL url: URL) {
        delegate?.tableViewCell(self, statusView: statusView, didTapCardWithURL: url)
    }

    func statusView(_ statusView: StatusView, mediaGridContainerView: MediaGridContainerView, mediaView: MediaView, didSelectMediaViewAt index: Int) {
        delegate?.tableViewCell(self, statusView: statusView, mediaGridContainerView: mediaGridContainerView, mediaView: mediaView, didSelectMediaViewAt: index)
    }

    func statusView(_ statusView: StatusView, pollTableView tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.tableViewCell(self, statusView: statusView, pollTableView: tableView, didSelectRowAt: indexPath)
    }

    func statusView(_ statusView: StatusView, pollVoteButtonPressed button: UIButton) {
        delegate?.tableViewCell(self, statusView: statusView, pollVoteButtonPressed: button)
    }

    func statusView(_ statusView: StatusView, actionToolbarContainer: ActionToolbarContainer, buttonDidPressed button: UIButton, action: ActionToolbarContainer.Action) {
        delegate?.tableViewCell(self, statusView: statusView, actionToolbarContainer: actionToolbarContainer, buttonDidPressed: button, action: action)
    }

    func statusView(_ statusView: StatusView, menuButton button: UIButton, didSelectAction action: MastodonMenu.Action) {
        delegate?.tableViewCell(self, statusView: statusView, menuButton: button, didSelectAction: action)
    }

    func statusView(_ statusView: StatusView, spoilerOverlayViewDidPressed overlayView: SpoilerOverlayView) {
        delegate?.tableViewCell(self, statusView: statusView, spoilerOverlayViewDidPressed: overlayView)
    }

    func statusView(_ statusView: StatusView, mediaGridContainerView: MediaGridContainerView, mediaSensitiveButtonDidPressed button: UIButton) {
        delegate?.tableViewCell(self, statusView: statusView, mediaGridContainerView: mediaGridContainerView, mediaSensitiveButtonDidPressed: button)
    }

    func statusView(_ statusView: StatusView, statusMetricView: StatusMetricView, reblogButtonDidPressed button: UIButton) {
        delegate?.tableViewCell(self, statusView: statusView, statusMetricView: statusMetricView, reblogButtonDidPressed: button)
    }

    func statusView(_ statusView: StatusView, statusMetricView: StatusMetricView, favoriteButtonDidPressed button: UIButton) {
        delegate?.tableViewCell(self, statusView: statusView, statusMetricView: statusMetricView, favoriteButtonDidPressed: button)
    }

    func statusView(_ statusView: StatusView, statusMetricView: StatusMetricView, showEditHistory button: UIButton) {
        delegate?.tableViewCell(self, statusView: statusView, statusMetricView: statusMetricView, showEditHistory: button)
    }

    func statusView(_ statusView: StatusView, cardControl: StatusCardControl, didTapURL url: URL) {
        delegate?.tableViewCell(self, statusView: statusView, cardControl: cardControl, didTapURL: url)
    }

    func statusView(_ statusView: StatusView, cardControl: StatusCardControl, didTapProfile account: Mastodon.Entity.Account) {
        delegate?.tableViewCell(self, statusView: statusView, cardControl: cardControl, didTapProfile: account)
    }

    func statusView(_ statusView: StatusView, cardControlMenu: StatusCardControl) -> [LabeledAction]? {
        return delegate?.tableViewCell(self, statusView: statusView, cardControlMenu: cardControlMenu)
    }

    func statusView(_ statusView: StatusView, accessibilityActivate: Void) {
        delegate?.tableViewCell(self, statusView: statusView, accessibilityActivate: accessibilityActivate)
    }
    // sourcery:end
}
