//
//  HomeTimelineViewController+DebugAction.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-5.
//

import os.log
import UIKit

#if DEBUG
extension HomeTimelineViewController {
    var debugMenu: UIMenu {
        let menu = UIMenu(
            title: "Debug Tools",
            image: nil,
            identifier: nil,
            options: .displayInline,
            children: [
                UIAction(title: "Show Public Timeline", image: UIImage(systemName: "list.dash"), attributes: []) { [weak self] action in
                    guard let self = self else { return }
                    self.showPublicTimelineAction(action)
                },
                UIAction(title: "Sign Out", image: UIImage(systemName: "escape"), attributes: .destructive) { [weak self] action in
                    guard let self = self else { return }
                    self.signOutAction(action)
                }
            ]
        )
        return menu
    }
}

extension HomeTimelineViewController {
    
    @objc private func showPublicTimelineAction(_ sender: UIAction) {
        coordinator.present(scene: .publicTimeline, from: self, transition: .show)
    }
    
    @objc private func signOutAction(_ sender: UIAction) {
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        let currentAccountCount = context.authenticationService.mastodonAuthentications.value.count
        let isAuthenticationExistWhenSignOut = currentAccountCount - 1 > 0
        // prepare advance
        let authenticationViewModel = AuthenticationViewModel(context: context, coordinator: coordinator, isAuthenticationExist: isAuthenticationExistWhenSignOut)

        context.authenticationService.signOutMastodonUser(
            domain: activeMastodonAuthenticationBox.domain,
            userID: activeMastodonAuthenticationBox.userID
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                assertionFailure(error.localizedDescription)
            case .success(let isSignOut):
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: sign out %s", ((#file as NSString).lastPathComponent), #line, #function, isSignOut ? "success" : "fail")
                guard isSignOut else { return }
                if !isAuthenticationExistWhenSignOut {
                    self.coordinator.present(scene: .authentication(viewModel: authenticationViewModel), from: nil, transition: .modal(animated: true, completion: nil))
                }
            }
        }
        .store(in: &disposeBag)
    }
    
}
#endif
