//
//  FamiliarFollowersDashboardView+ViewModel.swift
//  
//
//  Created by MainasuK on 2022-5-16.
//

import os.log
import UIKit
import Combine
import CoreDataStack
import MastodonCore
import MastodonMeta
import MastodonLocalization

extension FamiliarFollowersDashboardView {
    public final class ViewModel: ObservableObject {
        public var disposeBag = Set<AnyCancellable>()

        let logger = Logger(subsystem: "FamiliarFollowersDashboardView", category: "ViewModel")
        
        @Published var avatarURLs: [URL?] = []
        @Published var names: [String] = []
        @Published var emojis: MastodonContent.Emojis = [:]
        @Published var backgroundColor: UIColor?
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
                let avatarButton = AvatarButton()
                let origin = CGPoint(x: offset * CGFloat(i), y: 0)
                let size = CGSize(width: dimension, height: dimension)
                avatarButton.size = size
                avatarButton.frame = CGRect(origin: origin, size: size)
                view.avatarContainerView.addSubview(avatarButton)
                avatarButton.avatarImageView.configure(
                    configuration: .init(
                        url: avatarURL,
                        placeholder: .placeholder(color: .systemGray3)
                    )
                )
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
        
        Publishers.CombineLatest(
            $names,
            $emojis
        )
        .sink { names, emojis in
            let content: String = {
                guard names.count > 0 else { return " " }
                
                let count = names.count
                let firstTwoNames = names.prefix(2).joined(separator: ", ")
                
                switch names.count {
                case 1..<3:
                    return L10n.Scene.Familiarfollowers.followedByNames(firstTwoNames)
                default:
                    // Note: SwiftGen generates wrong formate argv for "%1$@" 
                    let remains = count - 2
                    let format = MastodonLocalization.bundle.localizedString(forKey: "plural.count.followed_by_and_mutual", value: nil, table: "Localizable")
                    return String(format: format, locale: .current, arguments: [firstTwoNames, remains])
                }
            }()
            let document = MastodonContent(content: content, emojis: emojis)
            do {
                let metaContent = try MastodonMetaContent.convert(document: document)
                view.descriptionMetaLabel.configure(content: metaContent)
            } catch {
                assertionFailure()
                view.descriptionMetaLabel.configure(content: PlaintextMetaContent(string: content))
            }            
        }
        .store(in: &disposeBag)
    }
}
