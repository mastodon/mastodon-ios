//
//  StatusProvider+KeyCommands.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-19.
//

import os.log
import UIKit

extension StatusTableViewControllerNavigateableCore where Self: StatusProvider & StatusTableViewControllerNavigateableRelay {

    var statusNavigationKeyCommands: [UIKeyCommand] {
        StatusTableViewNavigation.allCases.map { navigation in
            UIKeyCommand(
                title: navigation.title,
                image: nil,
                action: #selector(Self.statusKeyCommandHandlerRelay(_:)),
                input: navigation.input,
                modifierFlags: navigation.modifierFlags,
                propertyList: navigation.propertyList,
                alternates: [],
                discoverabilityTitle: nil,
                attributes: [],
                state: .off
            )
        }
    }

}

extension StatusTableViewControllerNavigateableCore where Self: StatusProvider {

    func statusKeyCommandHandler(_ sender: UIKeyCommand) {
        guard let rawValue = sender.propertyList as? String,
              let navigation = StatusTableViewNavigation(rawValue: rawValue) else { return }
        
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, navigation.title)
        switch navigation {
        case .openAuthorProfile:    openAuthorProfile()
        case .openRebloggerProfile: openRebloggerProfile()
        case .replyStatus:          replyStatus()
        case .toggleReblog:         toggleReblog()
        case .toggleFavorite:       toggleFavorite()
        case .toggleContentWarning: toggleContentWarning()
        case .previewImage:         previewImage()
        }
    }
    
}

// status coordinate
extension StatusTableViewControllerNavigateableCore where Self: StatusProvider {
    
    private func openAuthorProfile() {
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return }
        StatusProviderFacade.coordinateToStatusAuthorProfileScene(for: .primary, provider: self, indexPath: indexPathForSelectedRow)
    }
    
    private func openRebloggerProfile() {
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return }
        StatusProviderFacade.coordinateToStatusAuthorProfileScene(for: .secondary, provider: self, indexPath: indexPathForSelectedRow)
    }
    
    private func replyStatus() {
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return }
        StatusProviderFacade.responseToStatusReplyAction(provider: self, indexPath: indexPathForSelectedRow)
    }
    
    private func previewImage() {
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return }
        guard let provider = self as? (StatusProvider & MediaPreviewableViewController) else { return }
        guard let cell = tableView.cellForRow(at: indexPathForSelectedRow),
              let presentable = cell as? MosaicImageViewContainerPresentable else { return }
        let mosaicImageView = presentable.mosaicImageViewContainer
        guard let imageView = mosaicImageView.imageViews.first else { return }
        StatusProviderFacade.coordinateToStatusMediaPreviewScene(provider: provider, cell: cell, mosaicImageView: mosaicImageView, didTapImageView: imageView, atIndex: 0)
    }
    
}

// toggle
extension StatusTableViewControllerNavigateableCore where Self: StatusProvider {

    private func toggleReblog() {
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return }
        StatusProviderFacade.responseToStatusReblogAction(provider: self, indexPath: indexPathForSelectedRow)
    }
    
    private func toggleFavorite() {
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return }
        StatusProviderFacade.responseToStatusLikeAction(provider: self, indexPath: indexPathForSelectedRow)
    }
    
    private func toggleContentWarning() {
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return }
        StatusProviderFacade.responseToStatusContentWarningRevealAction(provider: self, indexPath: indexPathForSelectedRow)
    }
    
}
