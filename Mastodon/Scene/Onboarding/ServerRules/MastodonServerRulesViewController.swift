//
//  MastodonServerRulesViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-22.
//

import UIKit
import Combine
import MastodonSDK
import SafariServices
import MetaTextKit
import MastodonAsset
import MastodonCore
import MastodonLocalization
import SwiftUI

struct MastodonServerRulesView: View {
    let viewModel: MastodonServerRulesViewModel
    
    var onAgree: (() -> Void)?
    var onDisagree: (() -> Void)?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(LocalizedStringKey(L10n.Scene.ServerRules.subtitle(viewModel.domain)))
                    .padding(.bottom, 30)

                ForEach(Array(viewModel.rules.enumerated()), id: \.offset) { index, rule in
                    ZStack(alignment: .topLeading) {
                        Text("\(index + 1)")
                            .font(.system(size: UIFontMetrics.default.scaledValue(for: 24), weight: .bold))
                            .foregroundStyle(Asset.Colors.Brand.blurple.swiftUIColor)
                        Text(rule.text)
                            .padding(.leading, 30)
                    }
                    .padding(.bottom, 30)
                }
                

            }
        }
        .padding(.horizontal)
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(role: .cancel) {
                    onDisagree?()
                } label: {
                    Text(L10n.Scene.ServerRules.Button.disagree)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.clear)
                .foregroundStyle(Asset.Colors.Brand.blurple.swiftUIColor)
                
                Button {
                    onAgree?()
                } label: {
                    Text(L10n.Scene.ServerRules.Button.confirm)
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
            .padding()
            .background(.ultraThinMaterial)
            .tint(Asset.Colors.Brand.blurple.swiftUIColor)
        }
    }
}

private struct MastodonServerRulesButton: View {
    let text: LocalizedStringKey
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
        }
        .font(Font(UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 16, weight: .semibold))))
    }
}

final class MastodonServerRulesViewController: UIHostingController<MastodonServerRulesView>, NeedsDependency {

    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    private var viewModel: MastodonServerRulesViewModel!
    
    init(viewModel: MastodonServerRulesViewModel) {
        super.init(rootView: MastodonServerRulesView(
            viewModel: viewModel
        ))
        self.viewModel = viewModel
        self.rootView.onAgree = { self.nextButtonPressed(nil) }
        self.rootView.onDisagree = { self.backButtonPressed(nil) }
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MastodonServerRulesViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupOnboardingAppearance()
        defer { setupNavigationBarBackgroundView() }

        navigationItem.largeTitleDisplayMode = .always
        title = L10n.Scene.ServerRules.title
    }
}

extension MastodonServerRulesViewController {
    @objc private func backButtonPressed(_ sender: UIButton?) {
        navigationController?.popViewController(animated: true)
    }

    @objc private func nextButtonPressed(_ sender: UIButton?) {
        let domain = viewModel.domain
        let viewModel = PrivacyViewModel(domain: domain, authenticateInfo: viewModel.authenticateInfo, rows: [.iOSApp, .server(domain: domain)], instance: viewModel.instance, applicationToken: viewModel.applicationToken)

        _ = coordinator.present(scene: .mastodonPrivacyPolicies(viewModel: viewModel), from: self, transition: .show)
    }
}

// MARK: - OnboardingViewControllerAppearance
extension MastodonServerRulesViewController: OnboardingViewControllerAppearance { }
