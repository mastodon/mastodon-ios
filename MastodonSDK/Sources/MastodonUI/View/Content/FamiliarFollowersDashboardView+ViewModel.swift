//
//  FamiliarFollowersDashboardView+ViewModel.swift
//  
//
//  Created by MainasuK on 2022-5-16.
//

import UIKit
import Combine
import CoreDataStack
import Meta
import MastodonCore
import MastodonMeta
import MastodonLocalization

extension FamiliarFollowersDashboardView {
    public final class ViewModel: ObservableObject {
        public var disposeBag = Set<AnyCancellable>()
        
        @Published var avatarURLs: [URL?] = []
        @Published var names: [String] = []
        @Published var emojis: MastodonContent.Emojis = [:]
        @Published var backgroundColor: UIColor?

        @Published public var label: MetaContent?
    }
}

extension FamiliarFollowersDashboardView.ViewModel {
    func bind(view: FamiliarFollowersDashboardView) {
        Publishers.CombineLatest3(
            $avatarURLs,
            $backgroundColor,
            UIContentSizeCategory.publisher
        )
        .sink { avatarURLs, backgroundColor, contentSizeCategory in
            // only using first 4 items
            let avatarURLs = avatarURLs.prefix(4)

            view.avatarContainerView.subviews.forEach { $0.removeFromSuperview() }
            
            let initialOffset = min(12 * 1.5, UIFontMetrics(forTextStyle: .headline).scaledValue(for: 12))      // max 1.5x
            let offset = min(20 * 1.5, UIFontMetrics(forTextStyle: .headline).scaledValue(for: 20))
            let dimension = min(32 * 1.5, UIFontMetrics(forTextStyle: .headline).scaledValue(for: 32))
            let borderWidth = min(1.5, UIFontMetrics.default.scaledValue(for: 1))
            
            for (i, avatarURL) in avatarURLs.enumerated() {
                let avatarButton = AvatarButton(avatarPlaceholder: .placeholder(color: .systemGray3))
                let origin = CGPoint(x: offset * CGFloat(i), y: 0)
                let size = CGSize(width: dimension, height: dimension)
                avatarButton.size = size
                avatarButton.frame = CGRect(origin: origin, size: size)
                view.avatarContainerView.addSubview(avatarButton)
                avatarButton.avatarImageView.configure(with: avatarURL)
                avatarButton.avatarImageView.configure(
                    cornerConfiguration: .init(
                        corner: .fixed(radius: 7),
                        border: .init(
                            color: backgroundColor ?? .clear,
                            width: borderWidth
                        )
                    )
                )
            }
            
            let avatarContainerViewWidth = initialOffset + offset * CGFloat(avatarURLs.count)
            view.avatarContainerViewWidthLayoutConstraint.constant = avatarContainerViewWidth
            view.avatarContainerViewHeightLayoutConstraint.constant = dimension            
        }
        .store(in: &disposeBag)
        
        let label = Publishers.CombineLatest(
            $names,
            $emojis
        )
        .map { (names, emojis) -> MetaContent in
            let content: String = {
                guard names.count > 0 else { return " " }
                
                let count = names.count
                
                switch names.count {
                case 1:
                    return L10nLookup.Scene.FamiliarFollowers.followedByOneName(names[0])
                case 2:
                    return L10nLookup.Scene.FamiliarFollowers.followedByTwoNames(firstAccount: names[0], secondAccount: names[1])
                default:
                    let remainingCount = count - 2
                    return L10nLookup.Scene.FamiliarFollowers.followedByTwoNamesAndOthers(firstAccount: names[0], secondAccount: names[1], otherCount: remainingCount)
                }
            }()
            let document = MastodonContent(content: content, emojis: emojis)
            do {
                return try MastodonMetaContent.convert(document: document)
            } catch {
                assertionFailure()
                return PlaintextMetaContent(string: content)
            }            
        }

        label
            .sink { [weak self] metaContent in
                view.descriptionMetaLabel.configure(content: metaContent)
                self?.label = metaContent
            }
            .store(in: &disposeBag)
    }
}
