//
//  StatusNNode.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-6-19.
//

import UIKit
import Combine
import AsyncDisplayKit
import CoreDataStack

final class StatusNode: ASCellNode {

    var disposeBag = Set<AnyCancellable>()

    static let avatarImageSize = CGSize(width: 42, height: 42)
    static let avatarImageCornerRadius: CGFloat = 4

    let avatarImageNode: ASNetworkImageNode = {
        let node = ASNetworkImageNode()
        node.contentMode = .scaleAspectFill
        node.defaultImage = UIImage.placeholder(color: .systemFill)
        node.cornerRadius = StatusNode.avatarImageCornerRadius
        // node.cornerRoundingType = .precomposited
        return node
    }()

    let nameTextNode = ASTextNode()
    let nameDotTextNode = ASTextNode()
    let dateTextNode = ASTextNode()
    let usernameTextNode = ASTextNode()

    init(status: Status) {
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
        let createdAt = (status.reblog ?? status).createdAt
        dateTextNode.attributedText = NSAttributedString(string: createdAt.slowedTimeAgoSinceNow, attributes: [
            .foregroundColor: Asset.Colors.Label.secondary.color,
            .font: UIFont.systemFont(ofSize: 13, weight: .regular)
        ])
//        RunLoop.main.perform { [weak self] in
//            guard let self = self else { return }
//            AppContext.shared.timestampUpdatePublisher
//                .sink { [weak self] _ in
//                    guard let self = self else { return }
//                    self.dateTextNode.attributedText = NSAttributedString(string: createdAt.slowedTimeAgoSinceNow, attributes: [
//                        .foregroundColor: Asset.Colors.Label.secondary.color,
//                        .font: UIFont.systemFont(ofSize: 13, weight: .regular)
//                    ])
//                }
//                .store(in: &self.disposeBag)
//        }
        usernameTextNode.attributedText = NSAttributedString(string: "@" + status.author.acct, attributes: [
            .foregroundColor: Asset.Colors.Label.secondary.color,
            .font: UIFont.systemFont(ofSize: 15, weight: .regular)
        ])
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
        verticalStack.children = [
            headerStack
        ]

        return verticalStack
    }

}
