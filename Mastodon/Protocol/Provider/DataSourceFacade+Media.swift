//
//  DataSourceFacade+Media.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-26.
//

import UIKit
import CoreDataStack
import MastodonUI
import MastodonLocalization
import MastodonSDK

extension DataSourceFacade {
    
    @MainActor
    static func coordinateToMediaPreviewScene(
        dependency: NeedsDependency & MediaPreviewableViewController,
        mediaPreviewItem: MediaPreviewViewModel.PreviewItem,
        mediaPreviewTransitionItem: MediaPreviewTransitionItem
    ) {
        let mediaPreviewViewModel = MediaPreviewViewModel(
            context: dependency.context,
            item: mediaPreviewItem,
            transitionItem: mediaPreviewTransitionItem
        )
        _ = dependency.coordinator.present(
            scene: .mediaPreview(viewModel: mediaPreviewViewModel),
            from: dependency,
            transition: .custom(transitioningDelegate: dependency.mediaPreviewTransitionController)
        )
    }
    
}

extension DataSourceFacade {
    
    struct AttachmentPreviewContext {
        let containerView: ContainerView
        let mediaView: MediaView
        let index: Int
        
        enum ContainerView {
            case mediaView(MediaView)
            case mediaGridContainerView(MediaGridContainerView)
        }
        
        func thumbnails() async -> [UIImage?] {
            switch containerView {
            case .mediaView(let mediaView):
                let thumbnail = await mediaView.thumbnail()
                return [thumbnail]
            case .mediaGridContainerView(let mediaGridContainerView):
                let thumbnails = await mediaGridContainerView.mediaViews.parallelMap { mediaView in
                    return await mediaView.thumbnail()
                }
                return thumbnails
            }
        }
    }
    
    @MainActor
    static func coordinateToMediaPreviewScene(
        dependency: NeedsDependency & MediaPreviewableViewController,
        status: MastodonStatus,
        previewContext: AttachmentPreviewContext
    ) async throws {
        let status = status.reblog ?? status
        let attachments = status.entity.mastodonAttachments
        
        let thumbnails = await previewContext.thumbnails()
        
        let _source: MediaPreviewTransitionItem.Source? = {
            switch previewContext.containerView {
            case .mediaView(let mediaView):
                return .attachment(mediaView)
            case .mediaGridContainerView(let mediaGridContainerView):
                return .attachments(mediaGridContainerView)
            }
        }()
        guard let source = _source else {
            return
        }
        
        let mediaPreviewTransitionItem: MediaPreviewTransitionItem = {
            let item = MediaPreviewTransitionItem(
                source: source,
                previewableViewController: dependency
            )
            
            let mediaView = previewContext.mediaView

            item.initialFrame = {
                let initialFrame = mediaView.superview!.convert(mediaView.frame, to: nil)
                assert(initialFrame != .zero)
                return initialFrame
            }()
            
            let thumbnail = mediaView.thumbnail()
            item.image = thumbnail
            
            item.aspectRatio = {
                if let thumbnail = thumbnail {
                    return thumbnail.size
                }
                let index = previewContext.index
                guard index < attachments.count else { return nil }
                let size = attachments[index].size
                return size
            }()
            
            return item
        }()
        
        
        let mediaPreviewItem = MediaPreviewViewModel.PreviewItem.attachment(.init(
            attachments: attachments,
            initialIndex: previewContext.index,
            thumbnails: thumbnails
        ))
        
        coordinateToMediaPreviewScene(
            dependency: dependency,
            mediaPreviewItem: mediaPreviewItem,
            mediaPreviewTransitionItem: mediaPreviewTransitionItem
        )
    }
    
}

extension DataSourceFacade {
    
    struct ImagePreviewContext {
        let imageView: UIImageView
        let containerView: ContainerView
        
        enum ContainerView {
            case profileAvatar(ProfileHeaderView)
            case profileBanner(ProfileHeaderView)
        }
        
        func thumbnail() -> UIImage? {
            return imageView.image
        }
    }
    
    @MainActor
    static func coordinateToMediaPreviewScene(
        dependency: NeedsDependency & MediaPreviewableViewController,
        account: Mastodon.Entity.Account,
        previewContext: ImagePreviewContext
    ) async throws {

        let avatarAssetURL = account.avatar
        let headerAssetURL = account.header

        let thumbnail = previewContext.thumbnail()
        
        let source: MediaPreviewTransitionItem.Source
        switch previewContext.containerView {
            case .profileAvatar(let view): source = .profileAvatar(view)
            case .profileBanner(let view): source = .profileBanner(view)
        }

        let mediaPreviewTransitionItem = MediaPreviewTransitionItem(
            source: source,
            previewableViewController: dependency
        )

        let imageView = previewContext.imageView
        mediaPreviewTransitionItem.initialFrame = imageView.superview?.convert(imageView.frame, to: nil)
        mediaPreviewTransitionItem.image = thumbnail
        mediaPreviewTransitionItem.aspectRatio = thumbnail?.size ?? CGSize(width: 100, height: 100)
        mediaPreviewTransitionItem.sourceImageViewCornerRadius = {
            switch previewContext.containerView {
                case .profileAvatar:
                    return ProfileHeaderView.avatarImageViewCornerRadius
                case .profileBanner:
                    return 0
            }
        }()

        let mediaPreviewItem: MediaPreviewViewModel.PreviewItem
        switch previewContext.containerView {
            case .profileAvatar:
                mediaPreviewItem = .profileAvatar(.init(
                    assetURL: avatarAssetURL,
                    thumbnail: thumbnail
                ))
            case .profileBanner:
                mediaPreviewItem = .profileBanner(.init(
                    assetURL: headerAssetURL,
                    thumbnail: thumbnail
                ))
        }

        guard mediaPreviewItem.isAssetURLValid else {
            return
        }
        
        coordinateToMediaPreviewScene(
            dependency: dependency,
            mediaPreviewItem: mediaPreviewItem,
            mediaPreviewTransitionItem: mediaPreviewTransitionItem
        )
    }

}
