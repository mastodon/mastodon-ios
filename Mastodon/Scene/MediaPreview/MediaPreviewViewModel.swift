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
import MastodonCore

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
                switch attachment.kind {
                case .image:
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
                case .gifv:
                    let viewController = MediaPreviewVideoViewController()
                    let viewModel = MediaPreviewVideoViewModel(
                        context: context,
                        item: .gif(.init(
                            assetURL: attachment.assetURL.flatMap { URL(string: $0) },
                            previewURL: attachment.previewURL.flatMap { URL(string: $0) }
                        ))
                    )
                    viewController.viewModel = viewModel
                    viewControllers.append(viewController)
                case .video, .audio:
                    let viewController = MediaPreviewVideoViewController()
                    let viewModel = MediaPreviewVideoViewModel(
                        context: context,
                        item: .video(.init(
                            assetURL: attachment.assetURL.flatMap { URL(string: $0) },
                            previewURL: attachment.previewURL.flatMap { URL(string: $0) }
                        ))
                    )
                    viewController.viewModel = viewModel
                    viewControllers.append(viewController)
                }   // end switch attachment.kind { … }
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

        self.viewControllers = viewControllers
        self.currentPage = currentPage
        self.transitionItem = transitionItem
        super.init()
    }

}

extension MediaPreviewViewModel {
    
    enum PreviewItem {
        case attachment(AttachmentPreviewContext)
        case profileAvatar(ProfileAvatarPreviewContext)
        case profileBanner(ProfileBannerPreviewContext)
//        case local(LocalImagePreviewMeta)
        
        var isAssetURLValid: Bool {
            switch self {
            case .attachment:
                return true     // default valid
            case .profileAvatar:
                return true     // default valid
            case .profileBanner(let item):
                guard let assertURL = item.assetURL else { return false }
                guard !assertURL.hasSuffix("missing.png") else { return false }
                return true
            }
        }
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
