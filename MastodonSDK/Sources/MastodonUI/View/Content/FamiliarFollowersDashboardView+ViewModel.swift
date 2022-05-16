//
//  FamiliarFollowersDashboardView+ViewModel.swift
//  
//
//  Created by MainasuK on 2022-5-16.
//

import os.log
import UIKit
import Combine

extension FamiliarFollowersDashboardView {
    public final class ViewModel: ObservableObject {
        public var disposeBag = Set<AnyCancellable>()

        let logger = Logger(subsystem: "FamiliarFollowersDashboardView", category: "ViewModel")
        
        @Published var avatarURLs: [URL?] = []
        @Published var names: [String] = []
        @Published var backgroundColor: UIColor?
    }
}

extension FamiliarFollowersDashboardView.ViewModel {
    func bind(view: FamiliarFollowersDashboardView) {
        Publishers.CombineLatest(
            $avatarURLs,
            $backgroundColor
        )
        .sink { avatarURLs, backgroundColor in
            view.avatarContainerView.subviews.forEach { $0.removeFromSuperview() }
            for (i, avatarURL) in avatarURLs.enumerated() {
                let avatarButton = AvatarButton()
                let origin = CGPoint(x: 20 * i, y: 0)
                let size = CGSize(width: 32, height: 32)
                avatarButton.size = size
                avatarButton.frame = CGRect(origin: origin, size: size)
                view.avatarContainerView.addSubview(avatarButton)
                avatarButton.avatarImageView.configure(configuration: .init(url: avatarURL))
                avatarButton.avatarImageView.configure(
                    cornerConfiguration: .init(
                        corner: .fixed(radius: 7),
                        border: .init(
                            color: backgroundColor ?? .clear,
                            width: 1
                        )
                    )
                )
            }
            
            view.avatarContainerViewWidthLayoutConstraint.constant = CGFloat(12 + 20 * avatarURLs.count)
        }
        .store(in: &disposeBag)
        
        $names
            .sink { names in
                // TODO: i18n
                let description = "Followed by" + names.joined(separator: ", ")
                view.descriptionLabel.text = description
            }
            .store(in: &disposeBag)
    }
}
