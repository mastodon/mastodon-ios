//
//  MastodonServerRulesViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-22.
//

import os.log
import UIKit
import Combine

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
        label.textColor = .black
        label.text = "Rules"
        label.numberOfLines = 0
        return label
    }()
    
    let bottonContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.Background.onboardingBackground.color
        return view
    }()
    
    private(set) lazy var bottomPromptLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.text = L10n.Scene.ServerRules.prompt(viewModel.domain)
        label.numberOfLines = 0
        return label
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
        return scrollView
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
     
}

extension MastodonServerRulesViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupOnboardingAppearance()
        
        bottonContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottonContainerView)
        NSLayoutConstraint.activate([
            view.bottomAnchor.constraint(equalTo: bottonContainerView.bottomAnchor),
            bottonContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottonContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        bottonContainerView.preservesSuperviewLayoutMargins = true
        
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        bottonContainerView.addSubview(confirmButton)
        NSLayoutConstraint.activate([
            bottonContainerView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: confirmButton.bottomAnchor, constant: MastodonServerRulesViewController.viewBottomPaddingHeight),
            confirmButton.leadingAnchor.constraint(equalTo: bottonContainerView.readableContentGuide.leadingAnchor),
            confirmButton.trailingAnchor.constraint(equalTo: bottonContainerView.readableContentGuide.trailingAnchor),
            confirmButton.heightAnchor.constraint(equalToConstant: 46).priority(.defaultHigh),
        ])
        
        bottomPromptLabel.translatesAutoresizingMaskIntoConstraints = false
        bottonContainerView.addSubview(bottomPromptLabel)
        NSLayoutConstraint.activate([
            bottomPromptLabel.topAnchor.constraint(equalTo: bottonContainerView.topAnchor, constant: 20),
            bottomPromptLabel.leadingAnchor.constraint(equalTo: bottonContainerView.readableContentGuide.leadingAnchor),
            bottomPromptLabel.trailingAnchor.constraint(equalTo: bottonContainerView.readableContentGuide.trailingAnchor),
            confirmButton.topAnchor.constraint(equalTo: bottomPromptLabel.bottomAnchor, constant: 20),
        ])
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            view.readableContentGuide.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            scrollView.frameLayoutGuide.widthAnchor.constraint(equalTo: scrollView.contentLayoutGuide.widthAnchor),
            bottonContainerView.topAnchor.constraint(equalTo: scrollView.frameLayoutGuide.bottomAnchor),
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
        
        viewModel.isRegistering
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRegistering in
                guard let self = self else { return }
                isRegistering ? self.confirmButton.showLoading() : self.confirmButton.stopLoading()
            }
            .store(in: &disposeBag)
    }
    
}

extension MastodonServerRulesViewController {
    @objc private func confirmButtonPressed(_ sender: UIButton) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        let email = viewModel.registerQuery.email
        
        context.apiService.accountRegister(
            domain: viewModel.domain,
            query: viewModel.registerQuery,
            authorization: viewModel.applicationAuthorization
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self = self else { return }
            self.viewModel.isRegistering.value = false
            switch completion {
            case .failure(let error):
                self.viewModel.error.send(error)
            case .finished:
                break
            }
        } receiveValue: { [weak self] response in
            guard let self = self else { return }
            let userToken = response.value
            let viewModel = MastodonConfirmEmailViewModel(context: self.context, email: email, authenticateInfo: self.viewModel.authenticateInfo, userToken: userToken)
            self.coordinator.present(scene: .mastodonConfirmEmail(viewModel: viewModel), from: self, transition: .show)
        }
        .store(in: &disposeBag)
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
