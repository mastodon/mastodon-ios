//
//  ProfilePagingViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import os.log
import UIKit
import Pageboy
import Tabman

final class ProfilePagingViewModel: NSObject {
    
    let postUserTimelineViewController = UserTimelineViewController()
    let repliesUserTimelineViewController = UserTimelineViewController()
    let mediaUserTimelineViewController = UserTimelineViewController()
    
    init(
        postsUserTimelineViewModel: UserTimelineViewModel,
        repliesUserTimelineViewModel: UserTimelineViewModel,
        mediaUserTimelineViewModel: UserTimelineViewModel
    ) {
        postUserTimelineViewController.viewModel = postsUserTimelineViewModel
        repliesUserTimelineViewController.viewModel = repliesUserTimelineViewModel
        mediaUserTimelineViewController.viewModel = mediaUserTimelineViewModel
        super.init()
    }
    
    var viewControllers: [ScrollViewContainer] {
        return [
            postUserTimelineViewController,
            repliesUserTimelineViewController,
            mediaUserTimelineViewController,
        ]
    }
    
    let barItems: [TMBarItemable] = {
        let items = [
            TMBarItem(title: L10n.Scene.Profile.SegmentedControl.posts),
            TMBarItem(title: L10n.Scene.Profile.SegmentedControl.replies),
            TMBarItem(title: L10n.Scene.Profile.SegmentedControl.media),
        ]
        return items
    }()
    
    deinit {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

// MARK: - PageboyViewControllerDataSource
extension ProfilePagingViewModel: PageboyViewControllerDataSource {
    
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        return viewControllers[index]
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return .first
    }
    
}
