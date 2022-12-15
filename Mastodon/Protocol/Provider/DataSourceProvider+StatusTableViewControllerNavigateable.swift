//
//  DataSourceProvider+StatusTableViewControllerNavigateable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-16.
//

import os.log
import UIKit
import CoreDataStack
import MastodonCore

extension StatusTableViewControllerNavigateableCore where Self: DataSourceProvider & StatusTableViewControllerNavigateableRelay {

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

extension StatusTableViewControllerNavigateableCore where Self: DataSourceProvider & AuthContextProvider {

    func statusKeyCommandHandler(_ sender: UIKeyCommand) {
        guard let rawValue = sender.propertyList as? String,
              let navigation = StatusTableViewNavigation(rawValue: rawValue) else { return }
        
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: %s", ((#file as NSString).lastPathComponent), #line, #function, navigation.title)
        Task {
            switch navigation {
            case .openAuthorProfile:    await openAuthorProfile(target: .status)
            case .openRebloggerProfile: await openAuthorProfile(target: .reblog)
            case .replyStatus:          await replyStatus()
            case .toggleReblog:         await toggleReblog()
            case .toggleFavorite:       await toggleFavorite()
            case .toggleContentWarning: await toggleContentWarning()
            case .previewImage:         await previewImage()
            }
        }
    }
    
}

// status coordinate
extension StatusTableViewControllerNavigateableCore where Self: DataSourceProvider & AuthContextProvider {
    
    @MainActor
    private func statusRecord() async -> ManagedObjectRecord<Status>? {
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow else { return nil }
        let source = DataSourceItem.Source(indexPath: indexPathForSelectedRow)
        guard let item = await item(from: source) else { return nil }
        
        switch item {
        case .status(let record):
            return record
        case .notification(let record):
            let _statusRecord: ManagedObjectRecord<Status>? = try? await context.managedObjectContext.perform {
                guard let notification = record.object(in: self.context.managedObjectContext) else { return nil }
                guard let status = notification.status else { return nil }
                return .init(objectID: status.objectID)
            }
            guard let statusRecord = _statusRecord else {
                return nil
            }
            return statusRecord
        default:
            return nil
        }
    }

    @MainActor
    private func openAuthorProfile(target: DataSourceFacade.StatusTarget) async {
        guard let status = await statusRecord() else { return }
        await DataSourceFacade.coordinateToProfileScene(
            provider: self,
            target: target,
            status: status
        )
    }

    @MainActor
    private func replyStatus() async {
        guard let status = await statusRecord() else { return }
        
        let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        selectionFeedbackGenerator.selectionChanged()
        
        let composeViewModel = ComposeViewModel(
            context: self.context,
            authContext: authContext,
            destination: .reply(parent: status)
        )
        _ = self.coordinator.present(
            scene: .compose(viewModel: composeViewModel),
            from: self,
            transition: .modal(animated: true, completion: nil)
        )
    }
    
    @MainActor
    private func previewImage() async {
        guard let status = await statusRecord() else { return }
        
        // workaround media preview not first responder issue
        if let presentedViewController = presentedViewController as? MediaPreviewViewController {
            presentedViewController.dismiss(animated: true, completion: nil)
            return
        }

        guard let provider = self as? (DataSourceProvider & MediaPreviewableViewController) else { return }
        guard let indexPathForSelectedRow = tableView.indexPathForSelectedRow,
              let cell = tableView.cellForRow(at: indexPathForSelectedRow) as? StatusViewContainerTableViewCell
        else { return }

        guard let mediaView = cell.statusView.mediaGridContainerView.mediaViews.first else { return }
        
        do {
            try await DataSourceFacade.coordinateToMediaPreviewScene(
                dependency: provider,
                status: status,
                previewContext: DataSourceFacade.AttachmentPreviewContext(
                    containerView: .mediaGridContainerView(cell.statusView.mediaGridContainerView),
                    mediaView: mediaView,
                    index: 0
                )
            )
        } catch {
            assertionFailure()
        }
    }
    
}

// toggle
extension StatusTableViewControllerNavigateableCore where Self: DataSourceProvider & AuthContextProvider {

    @MainActor
    private func toggleReblog() async {
        guard let status = await statusRecord() else { return }
        
        do {
            try await DataSourceFacade.responseToStatusReblogAction(
                provider: self,
                status: status
            )
        } catch {
            assertionFailure()
        }
    }
    
    @MainActor
    private func toggleFavorite() async {
        guard let status = await statusRecord() else { return }

        do {
            try await DataSourceFacade.responseToStatusFavoriteAction(
                provider: self,
                status: status
            )
        } catch {
            assertionFailure()
        }
    }
    
    @MainActor
    private func toggleContentWarning() async {
        guard let status = await statusRecord() else { return }
        
        do {
            try await DataSourceFacade.responseToToggleSensitiveAction(
                dependency: self,
                status: status
            )
        } catch {
            assertionFailure()
        }
    }
    
}
