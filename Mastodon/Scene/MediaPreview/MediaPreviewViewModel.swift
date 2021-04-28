//
//  MediaPreviewViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import Pageboy

final class MediaPreviewViewModel: NSObject {
    
    // input
    let context: AppContext
    let initialItem: PreviewItem
    weak var mediaPreviewImageViewControllerDelegate: MediaPreviewImageViewControllerDelegate?
    let currentPage: CurrentValueSubject<Int, Never>
    
    // output
    let pushTransitionItem: MediaPreviewTransitionItem
    let viewControllers: [UIViewController]
    
    init(context: AppContext, meta: StatusImagePreviewMeta, pushTransitionItem: MediaPreviewTransitionItem) {
        self.context = context
        self.initialItem = .status(meta)
        var viewControllers: [UIViewController] = []
        let managedObjectContext = self.context.managedObjectContext
        managedObjectContext.performAndWait {
            let status = managedObjectContext.object(with: meta.statusObjectID) as! Status
            guard let media = status.mediaAttachments?.sorted(by: { $0.index.compare($1.index) == .orderedAscending }) else { return }
            for (entity, image) in zip(media, meta.preloadThumbnailImages) {
                let thumbnail: UIImage? = image.flatMap { $0.size != CGSize(width: 1, height: 1) ? $0 : nil }
                switch entity.type {
                case .image:
                    guard let url = URL(string: entity.url) else { continue }
                    let meta = MediaPreviewImageViewModel.RemoteImagePreviewMeta(url: url, thumbnail: thumbnail)
                    let mediaPreviewImageModel = MediaPreviewImageViewModel(meta: meta)
                    let mediaPreviewImageViewController = MediaPreviewImageViewController()
                    mediaPreviewImageViewController.viewModel = mediaPreviewImageModel
                    viewControllers.append(mediaPreviewImageViewController)
                default:
                    continue
                }
            }
        }
        self.viewControllers = viewControllers
        self.currentPage = CurrentValueSubject(meta.initialIndex)
        self.pushTransitionItem = pushTransitionItem
        super.init()
    }
    
    init(context: AppContext, meta: ProfileBannerImagePreviewMeta, pushTransitionItem: MediaPreviewTransitionItem) {
        self.context = context
        self.initialItem = .profileBanner(meta)
        var viewControllers: [UIViewController] = []
        let managedObjectContext = self.context.managedObjectContext
        managedObjectContext.performAndWait {
            let account = managedObjectContext.object(with: meta.accountObjectID) as! MastodonUser
            let avatarURL = account.headerImageURL() ?? URL(string: "https://example.com")!     // assert URL exist
            let meta = MediaPreviewImageViewModel.RemoteImagePreviewMeta(url: avatarURL, thumbnail: meta.preloadThumbnailImage)
            let mediaPreviewImageModel = MediaPreviewImageViewModel(meta: meta)
            let mediaPreviewImageViewController = MediaPreviewImageViewController()
            mediaPreviewImageViewController.viewModel = mediaPreviewImageModel
            viewControllers.append(mediaPreviewImageViewController)
        }
        self.viewControllers = viewControllers
        self.currentPage = CurrentValueSubject(0)
        self.pushTransitionItem = pushTransitionItem
        super.init()
    }
    
    init(context: AppContext, meta: ProfileAvatarImagePreviewMeta, pushTransitionItem: MediaPreviewTransitionItem) {
        self.context = context
        self.initialItem = .profileAvatar(meta)
        var viewControllers: [UIViewController] = []
        let managedObjectContext = self.context.managedObjectContext
        managedObjectContext.performAndWait {
            let account = managedObjectContext.object(with: meta.accountObjectID) as! MastodonUser
            let avatarURL = account.avatarImageURL() ?? URL(string: "https://example.com")!     // assert URL exist
            let meta = MediaPreviewImageViewModel.RemoteImagePreviewMeta(url: avatarURL, thumbnail: meta.preloadThumbnailImage)
            let mediaPreviewImageModel = MediaPreviewImageViewModel(meta: meta)
            let mediaPreviewImageViewController = MediaPreviewImageViewController()
            mediaPreviewImageViewController.viewModel = mediaPreviewImageModel
            viewControllers.append(mediaPreviewImageViewController)
        }
        self.viewControllers = viewControllers
        self.currentPage = CurrentValueSubject(0)
        self.pushTransitionItem = pushTransitionItem
        super.init()
    }
    
}

extension MediaPreviewViewModel {
    
    enum PreviewItem {
        case status(StatusImagePreviewMeta)
        case profileAvatar(ProfileAvatarImagePreviewMeta)
        case profileBanner(ProfileBannerImagePreviewMeta)
        case local(LocalImagePreviewMeta)
    }
    
    struct StatusImagePreviewMeta {
        let statusObjectID: NSManagedObjectID
        let initialIndex: Int
        let preloadThumbnailImages: [UIImage?]
    }
    
    struct ProfileAvatarImagePreviewMeta {
        let accountObjectID: NSManagedObjectID
        let preloadThumbnailImage: UIImage?
    }
    
    struct ProfileBannerImagePreviewMeta {
        let accountObjectID: NSManagedObjectID
        let preloadThumbnailImage: UIImage?
    }
    
    struct LocalImagePreviewMeta {
        let image: UIImage
    }
        
}

// MARK: - PageboyViewControllerDataSource
extension MediaPreviewViewModel: PageboyViewControllerDataSource {
    
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        let viewController = viewControllers[index]
        if let mediaPreviewImageViewController = viewController as? MediaPreviewImageViewController {
            mediaPreviewImageViewController.delegate = mediaPreviewImageViewControllerDelegate
        }
        return viewController
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        guard case let .status(meta) = initialItem else { return nil }
        return .at(index: meta.initialIndex)
    }
    
}
