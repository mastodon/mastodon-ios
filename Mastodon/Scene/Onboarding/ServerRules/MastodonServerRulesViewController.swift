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

final class MastodonServerRulesViewController: UIViewController, NeedsDependency {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: MastodonServerRulesViewModel!
    
    let largeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 34, weight: .bold))
        label.textColor = .label
        label.text = L10n.Scene.ServerRules.title
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
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = Asset.Colors.Label.primary.color
        label.text = "Rules"
        label.numberOfLines = 0
        return label
    }()
    
    let bottomContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.Background.onboardingBackground.color
        return view
    }()
    
    private(set) lazy var bottomPromptTextView: UITextView = {
        let textView = UITextView()
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textColor = .label
        textView.isSelectable = true
        textView.isEditable = false
        textView.backgroundColor = Asset.Colors.Background.onboardingBackground.color
        return textView
    }()
    
    let confirmButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.setTitleColor(.white, for: .normal)
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
            confirmButton.leadingAnchor.constraint(equalTo: bottomContainerView.readableContentGuide.leadingAnchor, constant: MastodonServerRulesViewController.actionButtonMargin),
            bottomContainerView.readableContentGuide.trailingAnchor.constraint(equalTo: confirmButton.trailingAnchor, constant: MastodonServerRulesViewController.actionButtonMargin),
            confirmButton.heightAnchor.constraint(equalToConstant: MastodonServerRulesViewController.actionButtonHeight).priority(.defaultHigh),
        ])
        
        bottomPromptTextView.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView.addSubview(bottomPromptTextView)
        NSLayoutConstraint.activate([
            bottomPromptTextView.frameLayoutGuide.topAnchor.constraint(equalTo: bottomContainerView.topAnchor, constant: 20),
            bottomPromptTextView.frameLayoutGuide.leadingAnchor.constraint(equalTo: bottomContainerView.readableContentGuide.leadingAnchor),
            bottomPromptTextView.frameLayoutGuide.trailingAnchor.constraint(equalTo: bottomContainerView.readableContentGuide.trailingAnchor),
            bottomPromptTextView.frameLayoutGuide.heightAnchor.constraint(equalToConstant: 50),
            confirmButton.topAnchor.constraint(equalTo: bottomPromptTextView.frameLayoutGuide.bottomAnchor, constant: 20),
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
                
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 10
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollViewContentInset()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateScrollViewContentInset()
    }
    
}

extension MastodonServerRulesViewController {
    func updateScrollViewContentInset() {
        view.layoutIfNeeded()
        scrollView.contentInset.bottom = bottomContainerView.frame.height
        scrollView.verticalScrollIndicatorInsets.bottom = bottomContainerView.frame.height
    }
    
    func configTextView() {
        let linkColor = Asset.Colors.Button.normal.color
        
        let str = NSString(string: L10n.Scene.ServerRules.prompt(viewModel.domain))
        let termsOfServiceRange = str.range(of: L10n.Scene.ServerRules.termsOfService)
        let privacyRange = str.range(of: L10n.Scene.ServerRules.privacyPolicy)
        let attributeString = NSMutableAttributedString(string: L10n.Scene.ServerRules.prompt(viewModel.domain), attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body), NSAttributedString.Key.foregroundColor: UIColor.label])
        attributeString.addAttribute(.link, value: Mastodon.API.serverRulesURL(domain: viewModel.domain), range: termsOfServiceRange)
        attributeString.addAttribute(.link, value: Mastodon.API.privacyURL(domain: viewModel.domain), range: privacyRange)
        let linkAttributes = [NSAttributedString.Key.foregroundColor:linkColor]
        bottomPromptTextView.attributedText = attributeString
        bottomPromptTextView.linkTextAttributes = linkAttributes
        bottomPromptTextView.delegate = self
    }
    
}

extension MastodonServerRulesViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let safariVC = SFSafariViewController(url: URL)
        self.present(safariVC, animated: true, completion: nil)
        return false
    }
}

extension MastodonServerRulesViewController {
    @objc private func confirmButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

        let viewModel = MastodonRegisterViewModel(domain: self.viewModel.domain, authenticateInfo: self.viewModel.authenticateInfo, instance: self.viewModel.instance, applicationToken: self.viewModel.applicationToken)
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
