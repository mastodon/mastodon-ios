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
    
    weak var mediaPreviewImageViewControllerDelegate: MediaPreviewImageViewControllerDelegate?

    // input
    let context: AppContext
    let item: PreviewItem
    let transitionItem: MediaPreviewTransitionItem
    
    @Published var currentPage: Int
    
    // output
    let viewControllers: [UIViewController]
    
    init(
        context: AppContext,
        item: PreviewItem,
        transitionItem: MediaPreviewTransitionItem
    ) {
        self.context = context
        self.item = item
        var currentPage = 0
        var viewControllers: [UIViewController] = []
        switch item {
        case .attachment(let previewContext):
            currentPage = previewContext.initialIndex
            for (i, attachment) in previewContext.attachments.enumerated() {
                let viewController = MediaPreviewImageViewController()
                let viewModel = MediaPreviewImageViewModel(
                    context: context,
                    item: .remote(.init(
                        assetURL: attachment.assetURL.flatMap { URL(string: $0) },
                        thumbnail: previewContext.thumbnail(at: i),
                        altText: attachment.altDescription
                    ))
                )
                viewController.viewModel = viewModel
                viewControllers.append(viewController)
            }   // end for … in …
        case .profileAvatar(let previewContext):
            let viewController = MediaPreviewImageViewController()
            let viewModel = MediaPreviewImageViewModel(
                context: context,
                item: .remote(.init(
                    assetURL: previewContext.assetURL.flatMap { URL(string: $0) },
                    thumbnail: previewContext.thumbnail,
                    altText: nil
                ))
            )
            viewController.viewModel = viewModel
            viewControllers.append(viewController)
        case .profileBanner(let previewContext):
            let viewController = MediaPreviewImageViewController()
            let viewModel = MediaPreviewImageViewModel(
                context: context,
                item: .remote(.init(
                    assetURL: previewContext.assetURL.flatMap { URL(string: $0) },
                    thumbnail: previewContext.thumbnail,
                    altText: nil
                ))
            )
            viewController.viewModel = viewModel
            viewControllers.append(viewController)
        }   // end switch
//            let status = managedObjectContext.object(with: meta.statusObjectID) as! Status
//            for (entity, image) in zip(status.attachments, meta.preloadThumbnailImages) {
//                let thumbnail: UIImage? = image.flatMap { $0.size != CGSize(width: 1, height: 1) ? $0 : nil }
//                switch entity.kind {
//                case .image:
//                    guard let url = URL(string: entity.assetURL ?? "") else { continue }
//                    let meta = MediaPreviewImageViewModel.RemoteImagePreviewMeta(url: url, thumbnail: thumbnail, altText: entity.altDescription)
//                    let mediaPreviewImageModel = MediaPreviewImageViewModel(meta: meta)
//                    let mediaPreviewImageViewController = MediaPreviewImageViewController()
//                    mediaPreviewImageViewController.viewModel = mediaPreviewImageModel
//                    viewControllers.append(mediaPreviewImageViewController)
//                default:
//                    continue
//                }
//            }
//        }
        self.viewControllers = viewControllers
        self.currentPage = currentPage
        self.transitionItem = transitionItem
        super.init()
    }
    
//    init(context: AppContext, meta: ProfileBannerImagePreviewMeta, pushTransitionItem: MediaPreviewTransitionItem) {
//        self.context = context
//        self.item = .profileBanner(meta)
//        var viewControllers: [UIViewController] = []
//        let managedObjectContext = self.context.managedObjectContext
//        managedObjectContext.performAndWait {
//            let account = managedObjectContext.object(with: meta.accountObjectID) as! MastodonUser
//            let avatarURL = account.headerImageURLWithFallback(domain: account.domain)
//            let meta = MediaPreviewImageViewModel.RemoteImagePreviewMeta(url: avatarURL, thumbnail: meta.preloadThumbnailImage, altText: nil)
//            let mediaPreviewImageModel = MediaPreviewImageViewModel(meta: meta)
//            let mediaPreviewImageViewController = MediaPreviewImageViewController()
//            mediaPreviewImageViewController.viewModel = mediaPreviewImageModel
//            viewControllers.append(mediaPreviewImageViewController)
//        }
//        self.viewControllers = viewControllers
//        self.currentPage = CurrentValueSubject(0)
//        self.transitionItem = pushTransitionItem
//        super.init()
//    }
//    
//    init(context: AppContext, meta: ProfileAvatarImagePreviewMeta, pushTransitionItem: MediaPreviewTransitionItem) {
//        self.context = context
//        self.item = .profileAvatar(meta)
//        var viewControllers: [UIViewController] = []
//        let managedObjectContext = self.context.managedObjectContext
//        managedObjectContext.performAndWait {
//            let account = managedObjectContext.object(with: meta.accountObjectID) as! MastodonUser
//            let avatarURL = account.avatarImageURLWithFallback(domain: account.domain)
//            let meta = MediaPreviewImageViewModel.RemoteImagePreviewMeta(url: avatarURL, thumbnail: meta.preloadThumbnailImage, altText: nil)
//            let mediaPreviewImageModel = MediaPreviewImageViewModel(meta: meta)
//            let mediaPreviewImageViewController = MediaPreviewImageViewController()
//            mediaPreviewImageViewController.viewModel = mediaPreviewImageModel
//            viewControllers.append(mediaPreviewImageViewController)
//        }
//        self.viewControllers = viewControllers
//        self.currentPage = CurrentValueSubject(0)
//        self.transitionItem = pushTransitionItem
//        super.init()
//    }
    
}

extension MediaPreviewViewModel {
    
    enum PreviewItem {
        case attachment(AttachmentPreviewContext)
        case profileAvatar(ProfileAvatarPreviewContext)
        case profileBanner(ProfileBannerPreviewContext)
//        case local(LocalImagePreviewMeta)
    }
    
    struct AttachmentPreviewContext {
        let attachments: [MastodonAttachment]
        let initialIndex: Int
        let thumbnails: [UIImage?]
        
        func thumbnail(at index: Int) -> UIImage? {
            guard index < thumbnails.count else { return nil }
            return thumbnails[index]
        }
    }
    
    struct ProfileAvatarPreviewContext {
        let assetURL: String?
        let thumbnail: UIImage?
    }

    struct ProfileBannerPreviewContext {
        let assetURL: String?
        let thumbnail: UIImage?
    }

//    struct LocalImagePreviewMeta {
//        let image: UIImage
//    }
        
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
        guard case let .attachment(previewContext) = item else { return nil }
        return .at(index: previewContext.initialIndex)
    }
    
}
