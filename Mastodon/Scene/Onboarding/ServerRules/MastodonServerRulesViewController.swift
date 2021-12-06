//
//  MastodonServerRulesViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-22.
//

import os.log
import UIKit
import Combine
import MastodonSDK
import SafariServices
import MetaTextKit

final class MastodonServerRulesViewController: UIViewController, NeedsDependency {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: MastodonServerRulesViewModel!
    
    let stackView = UIStackView()
    
    let largeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 34, weight: .bold))
        label.textColor = .label
        label.text = L10n.Scene.ServerRules.title
        label.numberOfLines = 0
        return label
    }()
    
    private(set) lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: UIFont.systemFont(ofSize: 20))
        label.textColor = .secondaryLabel
        label.text = L10n.Scene.ServerRules.subtitle(viewModel.domain)
        label.numberOfLines = 0
        return label
    }()
    
    let rulesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        label.textColor = Asset.Colors.Label.primary.color
        label.text = "Rules"
        label.numberOfLines = 0
        return label
    }()
    
    let bottomContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Theme.Mastodon.systemGroupedBackground.color
        return view
    }()
    
    private(set) lazy var bottomPromptMetaText: MetaText = {
        let metaText = MetaText()
        metaText.textAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular), maximumPointSize: 22),
            .foregroundColor: UIColor.label,
        ]
        metaText.linkAttributes = [
            .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .regular), maximumPointSize: 22),
            .foregroundColor: Asset.Colors.brandBlue.color,
        ]
        metaText.textView.isEditable = false
        metaText.textView.isSelectable = false
        metaText.textView.isScrollEnabled = false
        metaText.textView.backgroundColor = Asset.Theme.Mastodon.systemGroupedBackground.color      // needs background color to prevent server rules text overlap
        return metaText
    }()
    
    let confirmButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.setTitle(L10n.Scene.ServerRules.Button.confirm, for: .normal)
        return button
    }()
    
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
     
}

extension MastodonServerRulesViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupOnboardingAppearance()
        configureTitleLabel()
        configureMargin()
        configTextView()
        
        defer { setupNavigationBarBackgroundView() }
        
        bottomContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomContainerView)
        NSLayoutConstraint.activate([
            view.bottomAnchor.constraint(equalTo: bottomContainerView.bottomAnchor),
            bottomContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        bottomContainerView.preservesSuperviewLayoutMargins = true
        defer {
            view.bringSubviewToFront(bottomContainerView)
        }
        
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView.addSubview(confirmButton)
        NSLayoutConstraint.activate([
            bottomContainerView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: confirmButton.bottomAnchor, constant: MastodonServerRulesViewController.viewBottomPaddingHeight),
            confirmButton.leadingAnchor.constraint(equalTo: bottomContainerView.layoutMarginsGuide.leadingAnchor),
            bottomContainerView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: confirmButton.trailingAnchor),
            confirmButton.heightAnchor.constraint(equalToConstant: MastodonServerRulesViewController.actionButtonHeight).priority(.defaultHigh),
        ])
        
        bottomPromptMetaText.textView.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView.addSubview(bottomPromptMetaText.textView)
        NSLayoutConstraint.activate([
            bottomPromptMetaText.textView.frameLayoutGuide.topAnchor.constraint(equalTo: bottomContainerView.topAnchor, constant: 20),
            bottomPromptMetaText.textView.frameLayoutGuide.leadingAnchor.constraint(equalTo: bottomContainerView.layoutMarginsGuide.leadingAnchor),
            bottomPromptMetaText.textView.frameLayoutGuide.trailingAnchor.constraint(equalTo: bottomContainerView.layoutMarginsGuide.trailingAnchor),
            confirmButton.topAnchor.constraint(equalTo: bottomPromptMetaText.textView.frameLayoutGuide.bottomAnchor, constant: 20),
        ])
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.frameLayoutGuide.widthAnchor.constraint(equalTo: scrollView.contentLayoutGuide.widthAnchor),
        ])
                
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 10
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        stackView.addArrangedSubview(largeTitleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(rulesLabel)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
        ])
        
        rulesLabel.attributedText = viewModel.rulesAttributedString
        confirmButton.addTarget(self, action: #selector(MastodonServerRulesViewController.confirmButtonPressed(_:)), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        scrollView.flashScrollIndicators()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollViewContentInset()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateScrollViewContentInset()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setupNavigationBarAppearance()
        configureTitleLabel()
        configureMargin()
    }
    
}

extension MastodonServerRulesViewController {
    private func configureTitleLabel() {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return
        }
        
        switch traitCollection.horizontalSizeClass {
        case .regular:
            navigationItem.largeTitleDisplayMode = .always
            navigationItem.title = L10n.Scene.ServerRules.title.replacingOccurrences(of: "\n", with: " ")
            largeTitleLabel.isHidden = true
        default:
            navigationItem.leftBarButtonItem = nil
            navigationItem.largeTitleDisplayMode = .never
            navigationItem.title = nil
            largeTitleLabel.isHidden = false
        }
    }
    
    private func configureMargin() {
        switch traitCollection.horizontalSizeClass {
        case .regular:
            let margin = MastodonPickServerViewController.viewEdgeMargin
            stackView.layoutMargins = UIEdgeInsets(top: 32, left: margin, bottom: 20, right: margin)
            bottomContainerView.layoutMargins = UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin)
        default:
            stackView.layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
            bottomContainerView.layoutMargins = .zero
        }
    }
}

extension MastodonServerRulesViewController {
    func updateScrollViewContentInset() {
        view.layoutIfNeeded()
        scrollView.contentInset.bottom = bottomContainerView.frame.height
        scrollView.verticalScrollIndicatorInsets.bottom = bottomContainerView.frame.height
    }
    
    func configTextView() {
        let metaContent = ServerRulesPromptMetaContent(domain: viewModel.domain)
        bottomPromptMetaText.configure(content: metaContent)
        bottomPromptMetaText.textView.linkDelegate = self
    }
    
    struct ServerRulesPromptMetaContent: MetaContent {
        let string: String
        let entities: [Meta.Entity]
        
        init(domain: String) {
            let _string = L10n.Scene.ServerRules.prompt(domain)
            self.string = _string
            
            var _entities: [Meta.Entity] = []
            
            let termsOfServiceText = L10n.Scene.ServerRules.termsOfService
            if let termsOfServiceRange = _string.range(of: termsOfServiceText) {
                let url = Mastodon.API.serverRulesURL(domain: domain)
                let entity = Meta.Entity(range: NSRange(termsOfServiceRange, in: _string), meta: .url(termsOfServiceText, trimmed: termsOfServiceText, url: url.absoluteString, userInfo: nil))
                _entities.append(entity)
            }
            
            let privacyPolicyText = L10n.Scene.ServerRules.privacyPolicy
            if let privacyPolicyRange = _string.range(of: privacyPolicyText) {
                let url = Mastodon.API.privacyURL(domain: domain)
                let entity = Meta.Entity(range: NSRange(privacyPolicyRange, in: _string), meta: .url(privacyPolicyText, trimmed: privacyPolicyText, url: url.absoluteString, userInfo: nil))
                _entities.append(entity)
            }
            
            self.entities = _entities
        }
        
        func metaAttachment(for entity: Meta.Entity) -> MetaAttachment? {
            return nil
        }
    }
    
}

extension MastodonServerRulesViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return false
    }
}

// MARK: - MetaTextViewDelegate
extension MastodonServerRulesViewController: MetaTextViewDelegate {
    func metaTextView(_ metaTextView: MetaTextView, didSelectMeta meta: Meta) {
        switch meta {
        case .url(_, _, let url, _):
            guard let url = URL(string: url) else { return }
            coordinator.present(scene: .safari(url: url), from: nil, transition: .safariPresent(animated: true, completion: nil))
        default:
            break
        }
    }
}

extension MastodonServerRulesViewController {
    @objc private func confirmButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        let viewModel = MastodonRegisterViewModel(domain: self.viewModel.domain, context: self.context, authenticateInfo: self.viewModel.authenticateInfo, instance: self.viewModel.instance, applicationToken: self.viewModel.applicationToken)
        self.coordinator.present(scene: .mastodonRegister(viewModel: viewModel), from: self, transition: .show)
    }
}

// MARK: - OnboardingViewControllerAppearance
extension MastodonServerRulesViewController: OnboardingViewControllerAppearance { }

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ServerRulesViewController_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewControllerPreview {
            let viewController = MastodonServerRulesViewController()
            return viewController
        }
        .previewLayout(.fixed(width: 375, height: 800))
    }
    
}

#endif
