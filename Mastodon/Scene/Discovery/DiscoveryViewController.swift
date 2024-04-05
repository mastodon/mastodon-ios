//
//  DiscoveryViewController.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-12.
//

import UIKit
import Combine
import Pageboy
import MastodonAsset
import MastodonCore
import MastodonUI

public class DiscoveryViewController: PageboyViewController, NeedsDependency {

    public static let containerViewMarginForRegularHorizontalSizeClass: CGFloat = 64
    public static let containerViewMarginForCompactHorizontalSizeClass: CGFloat = 16
    
    var disposeBag = Set<AnyCancellable>()
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
        
    var viewModel: DiscoveryViewModel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        setupAppearance()
        
        dataSource = viewModel
        viewModel.$viewControllers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.reloadData()
            }
            .store(in: &disposeBag)
    }

    private func setupAppearance() {
        view.backgroundColor = .secondarySystemBackground
    }
}

// MARK: - ScrollViewContainer
extension DiscoveryViewController: ScrollViewContainer {
    var scrollView: UIScrollView {
        return (currentViewController as? ScrollViewContainer)?.scrollView ?? UIScrollView()
    }
    func scrollToTop(animated: Bool) {
        if scrollView.contentOffset.y <= 0 {
            scrollToPage(.first, animated: animated)
        } else {
            scrollView.scrollToTop(animated: animated)
        }
    }
}

extension DiscoveryViewController {

    public override var keyCommands: [UIKeyCommand]? {
        return pageboyNavigateKeyCommands
    }

}

// MARK: - PageboyNavigateable
extension DiscoveryViewController: PageboyNavigateable {
    
    var navigateablePageViewController: PageboyViewController {
        return self
    }
    
    @objc func pageboyNavigateKeyCommandHandlerRelay(_ sender: UIKeyCommand) {
        pageboyNavigateKeyCommandHandler(sender)
    }
}
