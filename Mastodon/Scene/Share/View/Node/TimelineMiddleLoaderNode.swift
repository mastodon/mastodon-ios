//
//  TimelineMiddleLoaderNode.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-6-19.
//

import UIKit
import AsyncDisplayKit

final class TimelineMiddleLoaderNode: ASCellNode {

    static let loadButtonFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .medium))

    let activityIndicatorNode = ASDisplayNode(viewBlock: {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    })

    let loadButtonNode = ASButtonNode()

    override init() {
        super.init()

        automaticallyManagesSubnodes = true

        loadButtonNode.setAttributedTitle(
            NSAttributedString(
                string: L10n.Common.Controls.Timeline.Loader.loadMissingPosts,
                attributes: [
                    .foregroundColor: Asset.Colors.brandBlue.color,
                    .font: TimelineMiddleLoaderNode.loadButtonFont
                ]),
            for: .normal
        )
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let contentStack = ASStackLayoutSpec.horizontal()
        contentStack.alignItems = .center
        contentStack.spacing = 7

        contentStack.children = [loadButtonNode]


        return contentStack
    }

}
