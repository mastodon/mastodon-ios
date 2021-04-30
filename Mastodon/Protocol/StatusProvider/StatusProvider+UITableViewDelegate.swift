//
//  StatusProvider+UITableViewDelegate.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-3.
//

import Combine
import CoreDataStack
import MastodonSDK
import os.log
import UIKit

extension StatusTableViewCellDelegate where Self: StatusProvider {
    
    func handleTableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // update poll when status appear
        let now = Date()
        var pollID: Mastodon.Entity.Poll.ID?
        status(for: cell, indexPath: indexPath)
            .compactMap { [weak self] status -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Poll>, Error>? in
                guard let self = self else { return nil }
                guard let authenticationBox = self.context.authenticationService.activeMastodonAuthenticationBox.value else { return nil }
                guard let status = (status?.reblog ?? status) else { return nil }
                guard let poll = status.poll else { return nil }
                pollID = poll.id
                
                // not expired AND last update > 60s
                guard !poll.expired else {
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: poll %s expired. Skip for update", (#file as NSString).lastPathComponent, #line, #function, poll.id)
                    return nil
                }
                let timeIntervalSinceUpdate = now.timeIntervalSince(poll.updatedAt)
                #if DEBUG
                let autoRefreshTimeInterval: TimeInterval = 3 // speedup testing
                #else
                let autoRefreshTimeInterval: TimeInterval = 60
                #endif
                guard timeIntervalSinceUpdate > autoRefreshTimeInterval else {
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: poll %s updated in the %.2fs. Skip for update", (#file as NSString).lastPathComponent, #line, #function, poll.id, timeIntervalSinceUpdate)
                    return nil
                }
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: poll %s info update…", (#file as NSString).lastPathComponent, #line, #function, poll.id)

                return self.context.apiService.poll(
                    domain: status.domain,
                    pollID: poll.id,
                    pollObjectID: poll.objectID,
                    mastodonAuthenticationBox: authenticationBox
                )
            }
            .setFailureType(to: Error.self)
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: poll %s info fail to update: %s", (#file as NSString).lastPathComponent, #line, #function, pollID ?? "?", error.localizedDescription)
                case .finished:
                    break
                }
            }, receiveValue: { response in
                let poll = response.value
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: poll %s info updated", (#file as NSString).lastPathComponent, #line, #function, poll.id)
            })
            .store(in: &disposeBag)
        
        status(for: cell, indexPath: indexPath)
            .sink { [weak self] status in
                guard let self = self else { return }
                let status = status?.reblog ?? status
                guard let media = (status?.mediaAttachments ?? Set()).first else { return }
                guard let videoPlayerViewModel = self.context.videoPlaybackService.dequeueVideoPlayerViewModel(for: media) else { return }
                
                DispatchQueue.main.async {
                    videoPlayerViewModel.willDisplay()
                }
            }
            .store(in: &disposeBag)
    }
    
    func handleTableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // os_log("%{public}s[%{public}ld], %{public}s: indexPath %s", ((#file as NSString).lastPathComponent), #line, #function, indexPath.debugDescription)
        
        status(for: cell, indexPath: indexPath)
            .sink { [weak self] status in
                guard let self = self else { return }
                guard let media = (status?.mediaAttachments ?? Set()).first else { return }
                
                if let videoPlayerViewModel = self.context.videoPlaybackService.dequeueVideoPlayerViewModel(for: media) {
                    DispatchQueue.main.async {
                        videoPlayerViewModel.didEndDisplaying()
                    }
                }
                if let currentAudioAttachment = self.context.audioPlaybackService.attachment,
                   status?.mediaAttachments?.contains(currentAudioAttachment) == true {
                    self.context.audioPlaybackService.pause()
                }
            }
            .store(in: &disposeBag)
    }
    
    func handleTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        StatusProviderFacade.coordinateToStatusThreadScene(for: .primary, provider: self, indexPath: indexPath)
    }
    
}

extension StatusTableViewCellDelegate where Self: StatusProvider {
    
    private typealias ImagePreviewPresentableCell = UITableViewCell & DisposeBagCollectable & MosaicImageViewContainerPresentable
    
    func handleTableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let imagePreviewPresentableCell = tableView.cellForRow(at: indexPath) as? ImagePreviewPresentableCell else { return nil }
        guard imagePreviewPresentableCell.isRevealing else { return nil }
        
        let status = status(for: nil, indexPath: indexPath)
        
        return contextMenuConfiguration(tableView, status: status, imagePreviewPresentableCell: imagePreviewPresentableCell, contextMenuConfigurationForRowAt: indexPath, point: point)
    }
        
    private func contextMenuConfiguration(
        _ tableView: UITableView,
        status: Future<Status?, Never>,
        imagePreviewPresentableCell presentable: ImagePreviewPresentableCell,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let imageViews = presentable.mosaicImageViewContainer.imageViews
        guard !imageViews.isEmpty else { return nil }

        for (i, imageView) in imageViews.enumerated() {
            let pointInImageView = imageView.convert(point, from: tableView)
            guard imageView.point(inside: pointInImageView, with: nil) else {
                continue
            }
            guard let image = imageView.image, image.size != CGSize(width: 1, height: 1) else {
                // not provide preview until image ready
                return nil
                
            }
            // setup preview
            let contextMenuImagePreviewViewModel = ContextMenuImagePreviewViewModel(aspectRatio: image.size, thumbnail: image)
            status
                .sink { status in
                    guard let status = (status?.reblog ?? status),
                          let media = status.mediaAttachments?.sorted(by:{ $0.index.compare($1.index) == .orderedAscending }),
                          i < media.count, let url = URL(string: media[i].url) else {
                        return
                    }
                    
                    contextMenuImagePreviewViewModel.url.value = url
                }
                .store(in: &contextMenuImagePreviewViewModel.disposeBag)
            
            // setup context menu
            let contextMenuConfiguration = TimelineTableViewCellContextMenuConfiguration(identifier: nil) { () -> UIViewController? in
                // know issue: preview size looks not as large as system default preview
                let previewProvider = ContextMenuImagePreviewViewController()
                previewProvider.viewModel = contextMenuImagePreviewViewModel
                return previewProvider
            } actionProvider: { _ -> UIMenu? in
                let savePhotoAction = UIAction(
                    title: L10n.Common.Controls.Actions.savePhoto, image: UIImage(systemName: "square.and.arrow.down")!, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off
                ) { [weak self] _ in
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: save photo", ((#file as NSString).lastPathComponent), #line, #function)
                    guard let self = self else { return }
                    self.attachment(of: status, index: i)
                        .setFailureType(to: Error.self)
                        .compactMap { attachment -> AnyPublisher<UIImage, Error>? in
                            guard let attachment = attachment, let url = URL(string: attachment.url) else { return nil }
                            return self.context.photoLibraryService.saveImage(url: url)
                        }
                        .sink(receiveCompletion: { _ in
                            // do nothing
                        }, receiveValue: { _ in
                            // do nothing
                        })
                        .store(in: &self.context.disposeBag)
                }
                let shareAction = UIAction(
                    title: L10n.Common.Controls.Actions.share, image: UIImage(systemName: "square.and.arrow.up")!, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off
                ) { [weak self] _ in
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: share", ((#file as NSString).lastPathComponent), #line, #function)
                    guard let self = self else { return }
                    self.attachment(of: status, index: i)
                        .sink(receiveValue: { [weak self] attachment in
                            guard let self = self else { return }
                            guard let attachment = attachment, let url = URL(string: attachment.url) else { return }
                            let applicationActivities: [UIActivity] = [
                                SafariActivity(sceneCoordinator: self.coordinator)
                            ]
                            let activityViewController = UIActivityViewController(
                                activityItems: [url],
                                applicationActivities: applicationActivities
                            )
                            activityViewController.popoverPresentationController?.sourceView = imageView
                            self.present(activityViewController, animated: true, completion: nil)
                        })
                        .store(in: &self.context.disposeBag)
                }
                let children = [savePhotoAction, shareAction]
                return UIMenu(title: "", image: nil, children: children)
            }
            contextMenuConfiguration.indexPath = indexPath
            contextMenuConfiguration.index = i
            return contextMenuConfiguration
        }
        
        return nil
    }
    
    private func attachment(of status: Future<Status?, Never>, index: Int) -> AnyPublisher<Attachment?, Never> {
        status
            .map { status in
                guard let status = status?.reblog ?? status else { return nil }
                guard let media = status.mediaAttachments?.sorted(by: { $0.index.compare($1.index) == .orderedAscending }) else { return nil }
                guard index < media.count else { return nil }
                return media[index]
            }
            .eraseToAnyPublisher()
    }
    
    func handleTableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return _handleTableView(tableView, configuration: configuration)
    }
    
    func handleTableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return _handleTableView(tableView, configuration: configuration)
    }
    
    private func _handleTableView(_ tableView: UITableView, configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let configuration = configuration as? TimelineTableViewCellContextMenuConfiguration else { return nil }
        guard let indexPath = configuration.indexPath, let index = configuration.index else { return nil }
        guard let cell = tableView.cellForRow(at: indexPath) as? ImagePreviewPresentableCell else {
            return nil
        }
        let imageViews = cell.mosaicImageViewContainer.imageViews
        guard index < imageViews.count else { return nil }
        let imageView = imageViews[index]
        return UITargetedPreview(view: imageView, parameters: UIPreviewParameters())
    }
    
    func handleTableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let previewableViewController = self as? MediaPreviewableViewController else { return }
        guard let configuration = configuration as? TimelineTableViewCellContextMenuConfiguration else { return }
        guard let indexPath = configuration.indexPath, let index = configuration.index else { return }
        guard let cell = tableView.cellForRow(at: indexPath) as? ImagePreviewPresentableCell else { return }
        let imageViews = cell.mosaicImageViewContainer.imageViews
        guard index < imageViews.count else { return }
        let imageView = imageViews[index]
        
        let status = status(for: nil, indexPath: indexPath)
        let initialFrame: CGRect? = {
            guard let previewViewController = animator.previewViewController else { return nil }
            return UIView.findContextMenuPreviewFrameInWindow(previewController: previewViewController)
        }()
        animator.preferredCommitStyle = .pop
        animator.addCompletion { [weak self] in
            guard let self = self else { return }
            status
                //.delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .sink { [weak self] status in
                    guard let self = self else { return }
                    guard let status = (status?.reblog ?? status) else { return }
                    
                    let meta = MediaPreviewViewModel.StatusImagePreviewMeta(
                        statusObjectID: status.objectID,
                        initialIndex: index,
                        preloadThumbnailImages: cell.mosaicImageViewContainer.thumbnails()
                    )
                    let pushTransitionItem = MediaPreviewTransitionItem(
                        source: .mosaic(cell.mosaicImageViewContainer),
                        previewableViewController: previewableViewController
                    )
                    pushTransitionItem.aspectRatio = {
                        if let image = imageView.image {
                            return image.size
                        }
                        guard let media = status.mediaAttachments?.sorted(by: { $0.index.compare($1.index) == .orderedAscending }) else { return nil }
                        guard index < media.count else { return nil }
                        let meta = media[index].meta
                        guard let width = meta?.original?.width, let height = meta?.original?.height else { return nil }
                        return CGSize(width: width, height: height)
                    }()
                    pushTransitionItem.sourceImageView = imageView
                    pushTransitionItem.initialFrame = {
                        if let initialFrame = initialFrame {
                            return initialFrame
                        }
                        return imageView.superview!.convert(imageView.frame, to: nil)
                    }()
                    pushTransitionItem.image = {
                        if let image = imageView.image {
                            return image
                        }
                        if index < cell.mosaicImageViewContainer.blurhashOverlayImageViews.count {
                            return cell.mosaicImageViewContainer.blurhashOverlayImageViews[index].image
                        }
                        
                        return nil
                    }()
                    let mediaPreviewViewModel = MediaPreviewViewModel(
                        context: self.context,
                        meta: meta,
                        pushTransitionItem: pushTransitionItem
                    )
                    DispatchQueue.main.async {
                        self.coordinator.present(scene: .mediaPreview(viewModel: mediaPreviewViewModel), from: self, transition: .custom(transitioningDelegate: previewableViewController.mediaPreviewTransitionController))
                    }
                }
                .store(in: &cell.disposeBag)
        }
    }


    

}

extension UIView {
    
    // hack to retrieve preview view frame in window
    fileprivate static func findContextMenuPreviewFrameInWindow(
        previewController: UIViewController
    ) -> CGRect? {
        guard let window = previewController.view.window else { return nil }
        
        let targetViews = window.subviews
            .map { $0.findSameSize(view: previewController.view) }
            .flatMap { $0 }
        for targetView in targetViews {
            guard let targetViewSuperview = targetView.superview else { continue }
            let frame = targetViewSuperview.convert(targetView.frame, to: nil)
            guard frame.origin.x > 0, frame.origin.y > 0 else { continue }
            return frame
        }
        
        return nil
    }
    
    private func findSameSize(view: UIView) -> [UIView] {
        var views: [UIView] = []

        if view.bounds.size == bounds.size {
            views.append(self)
        }
        
        for subview in subviews {
            let targetViews = subview.findSameSize(view: view)
            views.append(contentsOf: targetViews)
        }
        
        return views
    }
    
}
