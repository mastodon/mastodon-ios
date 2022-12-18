//
//  HomeTimelineNavigationBarTitleView.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/15.
//

import os.log
import UIKit
import MastodonUI
import MastodonAsset
import MastodonLocalization

protocol HomeTimelineNavigationBarTitleViewDelegate: AnyObject {
    func homeTimelineNavigationBarTitleView(_ titleView: HomeTimelineNavigationBarTitleView, logoButtonDidPressed sender: UIButton)
    func homeTimelineNavigationBarTitleView(_ titleView: HomeTimelineNavigationBarTitleView, buttonDidPressed sender: UIButton)
}

final class HomeTimelineNavigationBarTitleView: UIView {
    
    let containerView = UIStackView()
    
    let logoButton = HighlightDimmableButton()
    let button = RoundedEdgesButton()
    let label = UILabel()
    
    // input
    private var blockingState: HomeTimelineNavigationBarTitleViewModel.State?
    weak var delegate: HomeTimelineNavigationBarTitleViewDelegate?
    
    // output
    private(set) var state: HomeTimelineNavigationBarTitleViewModel.State = .logo
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension HomeTimelineNavigationBarTitleView {
    private func _init() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        containerView.pinToParent()
        
        containerView.addArrangedSubview(logoButton)
        button.translatesAutoresizingMaskIntoConstraints = false
        containerView.addArrangedSubview(button)
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 24).priority(.defaultHigh)
        ])
        containerView.addArrangedSubview(label)
        
        configure(state: .logo)
        logoButton.addTarget(self, action: #selector(HomeTimelineNavigationBarTitleView.logoButtonDidPressed(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(HomeTimelineNavigationBarTitleView.buttonDidPressed(_:)), for: .touchUpInside)
        
        logoButton.accessibilityIdentifier = "TitleButton"
        button.accessibilityIdentifier = "TitleButton"
    }
}

extension HomeTimelineNavigationBarTitleView {
    @objc private func logoButtonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.homeTimelineNavigationBarTitleView(self, logoButtonDidPressed: sender)
    }
    
    @objc private func buttonDidPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.homeTimelineNavigationBarTitleView(self, buttonDidPressed: sender)
    }
}

extension HomeTimelineNavigationBarTitleView {
    
    func resetContainer() {
        logoButton.isHidden = true
        button.isHidden = true
        label.isHidden = true
    }
    
    func configure(state: HomeTimelineNavigationBarTitleViewModel.State) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: configure title view: %s", ((#file as NSString).lastPathComponent), #line, #function, state.rawValue)
        self.state = state
    
        // check state block or not
        guard blockingState == nil else {
            return
        }
        
        resetContainer()
        
        switch state {
        case .logo:
            logoButton.tintColor = Asset.Colors.Label.primary.color
            logoButton.setImage(Asset.Asset.mastodonTextLogo.image.withRenderingMode(.alwaysTemplate), for: .normal)
            logoButton.contentMode = .center
            logoButton.isHidden = false
            logoButton.accessibilityLabel = "Logo Button"   // TODO :i18n
            logoButton.accessibilityHint = "Tap to scroll to top and tap again to previous location"
        case .newPostButton:
            configureButton(
                title: L10n.Scene.HomeTimeline.NavigationBarState.newPosts,
                textColor: .white,
                backgroundColor: Asset.Colors.brand.color
            )
            button.isHidden = false
            button.accessibilityLabel = L10n.Scene.HomeTimeline.NavigationBarState.newPosts
        case .offlineButton:
            configureButton(
                title: L10n.Scene.HomeTimeline.NavigationBarState.offline,
                textColor: .white,
                backgroundColor: Asset.Colors.danger.color
            )
            button.isHidden = false
            button.accessibilityLabel = L10n.Scene.HomeTimeline.NavigationBarState.offline
        case .publishingPostLabel:
            label.font = .systemFont(ofSize: 17, weight: .semibold)
            label.textColor = Asset.Colors.Label.primary.color
            label.text = L10n.Scene.HomeTimeline.NavigationBarState.publishing
            label.textAlignment = .center
            label.isHidden = false
            button.accessibilityLabel = L10n.Scene.HomeTimeline.NavigationBarState.publishing
        case .publishedButton:
            blockingState = state
            configureButton(
                title: L10n.Scene.HomeTimeline.NavigationBarState.published,
                textColor: .white,
                backgroundColor: Asset.Colors.successGreen.color
            )
            button.isHidden = false
            button.accessibilityLabel = L10n.Scene.HomeTimeline.NavigationBarState.published
            
            let presentDuration: TimeInterval = 0.33
            let scaleAnimator = UIViewPropertyAnimator(duration: presentDuration, timingParameters: UISpringTimingParameters())
            button.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            scaleAnimator.addAnimations {
                self.button.transform = .identity
            }
            let alphaAnimator = UIViewPropertyAnimator(duration: presentDuration, curve: .easeInOut)
            button.alpha = 0.3
            alphaAnimator.addAnimations {
                self.button.alpha = 1
            }
            scaleAnimator.startAnimation()
            alphaAnimator.startAnimation()
            
            let dismissDuration: TimeInterval = 3
            let dissolveAnimator = UIViewPropertyAnimator(duration: dismissDuration, curve: .easeInOut)
            dissolveAnimator.addAnimations({
                self.button.alpha = 0
            }, delayFactor: 0.9)    // at 2.7s
            dissolveAnimator.addCompletion { _ in
                self.blockingState = nil
                self.configure(state: self.state)
                self.button.alpha = 1
            }
            dissolveAnimator.startAnimation()
        }
    }
    
    private func configureButton(title: String, textColor: UIColor, backgroundColor: UIColor) {
        button.setBackgroundImage(.placeholder(color: backgroundColor), for: .normal)
        button.setBackgroundImage(.placeholder(color: backgroundColor.withAlphaComponent(0.5)), for: .highlighted)
        button.setTitleColor(textColor, for: .normal)
        button.setTitleColor(textColor.withAlphaComponent(0.5), for: .highlighted)
        button.setTitle(title, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 1, left: 16, bottom: 1, right: 16)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
    }

}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct HomeTimelineNavigationBarTitleView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) {
                let titleView = HomeTimelineNavigationBarTitleView()
                titleView.configure(state: .logo)
                return titleView
            }
            .previewLayout(.fixed(width: 375, height: 44))
            UIViewPreview(width: 150) {
                let titleView = HomeTimelineNavigationBarTitleView()
                titleView.configure(state: .newPostButton)
                return titleView
            }
            .previewLayout(.fixed(width: 150, height: 24))
            UIViewPreview(width: 120) {
                let titleView = HomeTimelineNavigationBarTitleView()
                titleView.configure(state: .offlineButton)
                return titleView
            }
            .previewLayout(.fixed(width: 120, height: 24))
            UIViewPreview(width: 375) {
                let titleView = HomeTimelineNavigationBarTitleView()
                titleView.configure(state: .publishingPostLabel)
                return titleView
            }
            .previewLayout(.fixed(width: 375, height: 44))
            UIViewPreview(width: 120) {
                let titleView = HomeTimelineNavigationBarTitleView()
                titleView.configure(state: .publishedButton)
                return titleView
            }
            .previewLayout(.fixed(width: 120, height: 24))
        }
    }
    
}

#endif

