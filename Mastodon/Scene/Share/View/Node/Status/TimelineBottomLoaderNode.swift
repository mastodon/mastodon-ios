//
//  TimelineBottomLoaderNode.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-6-19.
//

#if ASDK

import UIKit
import AsyncDisplayKit

final class TimelineBottomLoaderNode: ASCellNode {

    let activityIndicatorNode = ActivityIndicatorNode()

    override init() {
        super.init()

        automaticallyManagesSubnodes = true
        activityIndicatorNode.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let contentStack = ASStackLayoutSpec.horizontal()
        contentStack.alignItems = .center
        contentStack.spacing = 7

        contentStack.children = [activityIndicatorNode]

        return contentStack
    }

    override func didEnterDisplayState() {
        super.didEnterDisplayState()
        activityIndicatorNode.animating = true
    }

}

#endif
