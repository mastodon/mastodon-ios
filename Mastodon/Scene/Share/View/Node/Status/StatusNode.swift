//
//  StatusNNode.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-6-19.
//

#if ASDK

import UIKit
import Combine
import AsyncDisplayKit
import CoreDataStack
import ActiveLabel
import func AVFoundation.AVMakeRect

protocol StatusNodeDelegate: AnyObject {
    func statusNode(_ node: StatusNode, statusContentTextNode: ASMetaEditableTextNode, didSelectActiveEntityType type: ActiveEntityType)
}

final class StatusNode: ASCellNode {

    var disposeBag = Set<AnyCancellable>()
    var timestamp: Date
    var timestampSubscription: AnyCancellable?

    weak var delegate: StatusNodeDelegate?      // needs assign on main queue

    static let avatarImageSize = CGSize(width: 42, height: 42)
    static let avatarImageCornerRadius: CGFloat = 4

    static let statusContentAppearance: MastodonStatusContent.Appearance = {
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold)),
            .foregroundColor: Asset.Colors.brandBlue.color
        ]
        return MastodonStatusContent.Appearance(
            attributes: [
                .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular)),
                .foregroundColor: Asset.Colors.Label.primary.color
            ],
            urlAttributes: linkAttributes,
            hashtagAttributes: linkAttributes,
            mentionAttributes: linkAttributes
        )
    }()

    let avatarImageNode: ASNetworkImageNode = {
        let node = ASNetworkImageNode()
        node.contentMode = .scaleAspectFill
        node.defaultImage = UIImage.placeholder(color: .systemFill)
        node.forcedSize = StatusNode.avatarImageSize
        node.cornerRadius = StatusNode.avatarImageCornerRadius
        // node.cornerRoundingType = .precomposited
        // node.shouldRenderProgressImages = true
        return node
    }()
    let nameTextNode = ASTextNode()
    let nameDotTextNode = ASTextNode()
    let dateTextNode = ASTextNode()
    let usernameTextNode = ASTextNode()
    let statusContentTextNode: ASMetaEditableTextNode = {
        let node = ASMetaEditableTextNode()
        node.scrollEnabled = false
        return node
    }()

    let mosaicImageViewModel: MosaicImageViewModel
    let mediaMultiplexImageNodes: [ASMultiplexImageNode]

    init(status: Status) {
        timestamp = (status.reblog ?? status).createdAt
        let _mosaicImageViewModel: MosaicImageViewModel = {
            let mediaAttachments = Array((status.reblog ?? status).mediaAttachments ?? []).sorted { $0.index.compare($1.index) == .orderedAscending }
            return MosaicImageViewModel(mediaAttachments: mediaAttachments)
        }()
        mosaicImageViewModel = _mosaicImageViewModel
        mediaMultiplexImageNodes = {
            var imageNodes: [ASMultiplexImageNode] = []
            for _ in 0..<_mosaicImageViewModel.metas.count {
                let imageNode = ASMultiplexImageNode()   // TODO: adapt downloader
                imageNode.downloadsIntermediateImages = true
                imageNode.imageIdentifiers = ["url", "previewURL"].map { $0 as NSString }      // quality in descending order
                imageNodes.append(imageNode)
            }
            return imageNodes
        }()
        super.init()

        automaticallyManagesSubnodes = true

        if let url = (status.reblog ?? status).author.avatarImageURL() {
            avatarImageNode.url = url
        }

        nameTextNode.attributedText = NSAttributedString(string: status.author.displayNameWithFallback, attributes: [
            .foregroundColor: Asset.Colors.Label.primary.color,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ])
        nameDotTextNode.attributedText = NSAttributedString(string: "·", attributes: [
            .foregroundColor: Asset.Colors.Label.secondary.color,
            .font: UIFont.systemFont(ofSize: 13, weight: .regular)
        ])
        // set date
        dateTextNode.attributedText = NSAttributedString(string: timestamp.slowedTimeAgoSinceNow, attributes: [
            .foregroundColor: Asset.Colors.Label.secondary.color,
            .font: UIFont.systemFont(ofSize: 13, weight: .regular)
        ])

        usernameTextNode.attributedText = NSAttributedString(string: "@" + status.author.acct, attributes: [
            .foregroundColor: Asset.Colors.Label.secondary.color,
            .font: UIFont.systemFont(ofSize: 15, weight: .regular)
        ])

        statusContentTextNode.metaEditableTextNodeDelegate = self
        if let parseResult = try? MastodonStatusContent.parse(
            content: (status.reblog ?? status).content,
            emojiDict: (status.reblog ?? status).emojiDict
        ) {
            statusContentTextNode.attributedText = parseResult.trimmedAttributedString(appearance: StatusNode.statusContentAppearance)
        }

        for imageNode in mediaMultiplexImageNodes {
            imageNode.dataSource = self
        }
    }

    override func didEnterDisplayState() {
        super.didEnterDisplayState()

        timestampSubscription = AppContext.shared.timestampUpdatePublisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.dateTextNode.attributedText = NSAttributedString(string: self.timestamp.slowedTimeAgoSinceNow, attributes: [
                    .foregroundColor: Asset.Colors.Label.secondary.color,
                    .font: UIFont.systemFont(ofSize: 13, weight: .regular)
                ])
            }

        // FIXME: needs move to other only once called callback in life cycle like: `viewDidLoad`
        statusContentTextNode.textView.isEditable = false
        statusContentTextNode.textView.textDragInteraction?.isEnabled = false
        statusContentTextNode.textView.linkTextAttributes = [
            .foregroundColor: Asset.Colors.brandBlue.color
        ]
    }

    override func didExitVisibleState() {
        super.didExitVisibleState()
        timestampSubscription = nil
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let headerStack = ASStackLayoutSpec.horizontal()
        headerStack.alignItems = .center
        headerStack.spacing = 5
        var headerStackChildren: [ASLayoutElement] = []

        avatarImageNode.style.preferredSize = StatusNode.avatarImageSize
        headerStackChildren.append(avatarImageNode)

        let authorMetaHeaderStack = ASStackLayoutSpec.horizontal()
        authorMetaHeaderStack.alignItems = .center
        authorMetaHeaderStack.spacing = 4
        authorMetaHeaderStack.children = [
            nameTextNode,
            nameDotTextNode,
            dateTextNode,
        ]
        let authorMetaStack = ASStackLayoutSpec.vertical()
        authorMetaStack.children = [
            authorMetaHeaderStack,
            usernameTextNode,
        ]

        headerStackChildren.append(authorMetaStack)

        headerStack.children = headerStackChildren

        let verticalStack = ASStackLayoutSpec.vertical()
        verticalStack.spacing = 10
        var verticalStackChildren: [ASLayoutElement] = [
            headerStack,
            statusContentTextNode,
        ]
        if !mediaMultiplexImageNodes.isEmpty {
            for (imageNode, meta) in zip(mediaMultiplexImageNodes, mosaicImageViewModel.metas) {
                imageNode.style.preferredSize = AVMakeRect(aspectRatio: meta.size, insideRect: CGRect(origin: .zero, size: constrainedSize.max)).size
                let layout = ASRatioLayoutSpec(ratio: meta.size.height / meta.size.width, child: imageNode)
                verticalStackChildren.append(layout)
            }
        }
        verticalStack.children = verticalStackChildren

        return verticalStack
    }

}

//extension StatusNode: ASImageDownloaderProtocol {
//    func downloadImage(with URL: URL, callbackQueue: DispatchQueue, downloadProgress: ASImageDownloaderProgress?, completion: @escaping ASImageDownloaderCompletion) -> Any? {
//
//    }
//
//    func cancelImageDownload(forIdentifier downloadIdentifier: Any) {
//
//    }
//}

// MARK: - ASEditableTextNodeDelegate
extension StatusNode: ASMetaEditableTextNodeDelegate {
    func metaEditableTextNode(_ textNode: ASMetaEditableTextNode, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard let activityEntityType = ActiveEntityType(url: URL) else {
            return false
        }
        defer {
            delegate?.statusNode(self, statusContentTextNode: textNode, didSelectActiveEntityType: activityEntityType)
        }
        return false
    }
}

// MARK: - ASMultiplexImageNodeDataSource
extension StatusNode: ASMultiplexImageNodeDataSource {
    func multiplexImageNode(_ imageNode: ASMultiplexImageNode, urlForImageIdentifier imageIdentifier: ASImageIdentifier) -> URL? {
        guard let imageNodeIndex = mediaMultiplexImageNodes.firstIndex(of: imageNode) else { return nil }
        guard imageNodeIndex < mosaicImageViewModel.metas.count else { return nil }
        let meta = mosaicImageViewModel.metas[imageNodeIndex]
        switch imageIdentifier {
        case "url" as NSString:
            return meta.url
        case "previewURL" as NSString:
            return meta.priviewURL
        default:
            assertionFailure()
            return nil
        }
    }
}

#endif
