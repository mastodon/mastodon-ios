//
//  HomeViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import os.log
import UIKit
import Combine

final class HomeViewController: UIViewController, NeedsDependency {
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: HomeViewModel!
    
    let avatarBarButtonItem = AvatarBarButtonItem()
    
}

extension HomeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Home"
        view.backgroundColor = Asset.Colors.Background.systemBackground.color
        navigationItem.leftBarButtonItem = avatarBarButtonItem
        avatarBarButtonItem.avatarButton.addTarget(self, action: #selector(HomeViewController.avatarBarButtonItemDidPressed(_:)), for: .touchUpInside)
        #if DEBUG
        avatarBarButtonItem.avatarButton.menu = debugMenu
        avatarBarButtonItem.avatarButton.showsMenuAsPrimaryAction = true
        #endif
        
        Publishers.CombineLatest(
            context.authenticationService.activeMastodonAuthentication.eraseToAnyPublisher(),
            viewModel.viewDidAppear.eraseToAnyPublisher()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] activeMastodonAuthentication, _ in
            guard let self = self else { return }
            guard let user = activeMastodonAuthentication?.user,
                  let avatarImageURL = user.avatarImageURL() else {
                let input = AvatarConfigurableViewConfiguration.Input(avatarImageURL: nil)
                self.avatarBarButtonItem.configure(withConfigurationInput: input)
                return
            }
            let input = AvatarConfigurableViewConfiguration.Input(avatarImageURL: avatarImageURL)
            self.avatarBarButtonItem.configure(withConfigurationInput: input)
        }
        .store(in: &disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.viewDidAppear.send()
    }
    
}

extension HomeViewController {
    @objc private func avatarBarButtonItemDidPressed(_ sender: UIBarButtonItem) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)

    }
}
