//
//  HomeTimelineNavigationBarView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/15.
//

import UIKit

final class HomeTimelineNavigationBarView {
    static let mastodonLogoTitleView: UIImageView = {
        let imageView = UIImageView(image: Asset.Asset.mastodonTextLogo.image.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = Asset.Colors.Label.primary.color
        return imageView
    }()
    
    static let offlineView: UIView = {
        let view = HomeTimelineNavigationBarView.backgroundViewWithColor(color: Asset.Colors.lightDangerRed.color)
        let label = HomeTimelineNavigationBarView.contentLabel(text: L10n.Scene.HomeTimeline.NavigationBarState.offline)
        HomeTimelineNavigationBarView.addLabelToView(label: label, view: view)
        return view
    }()
    
    static let newPostsView: UIView = {
        let view = HomeTimelineNavigationBarView.backgroundViewWithColor(color: Asset.Colors.Button.highlight.color)
        let label = HomeTimelineNavigationBarView.contentLabel(text: L10n.Scene.HomeTimeline.NavigationBarState.newPosts)
        HomeTimelineNavigationBarView.addLabelToView(label: label, view: view)
        return view
    }()
    
    static var publishedView: UIView = {
        let view = HomeTimelineNavigationBarView.backgroundViewWithColor(color: Asset.Colors.lightSuccessGreen.color)
        let label = HomeTimelineNavigationBarView.contentLabel(text: L10n.Scene.HomeTimeline.NavigationBarState.published)
        HomeTimelineNavigationBarView.addLabelToView(label: label, view: view)
        return view
    }()
    
    static var progressView: NavigationBarProgressView = {
        let view = NavigationBarProgressView()
        return view
    }()
    
    static var publishingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        label.text = L10n.Scene.HomeTimeline.NavigationBarState.publishing
        return label
    }()
    
    static func addLabelToView(label: UILabel, view: UIView) {
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            view.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 1),
            view.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 1)
        ])
        label.sizeToFit()
        view.layoutIfNeeded()
        view.layer.cornerRadius = view.frame.height / 2
        view.clipsToBounds = true
    }
    
    static func backgroundViewWithColor(color: UIColor) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    static func contentLabel(text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .bold))
        label.text = text
        return label
    }
}
