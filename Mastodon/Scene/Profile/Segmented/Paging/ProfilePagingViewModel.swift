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
import MastodonAsset
import MastodonLocalization

final class ProfilePagingViewModel: NSObject {
    
    let postUserTimelineViewController = UserTimelineViewController()
    let repliesUserTimelineViewController = UserTimelineViewController()
    let mediaUserTimelineViewController = UserTimelineViewController()
    let profileAboutViewController = ProfileAboutViewController()
    
    init(
        postsUserTimelineViewModel: UserTimelineViewModel,
        repliesUserTimelineViewModel: UserTimelineViewModel,
        mediaUserTimelineViewModel: UserTimelineViewModel,
        profileAboutViewModel: ProfileAboutViewModel
    ) {
        postUserTimelineViewController.viewModel = postsUserTimelineViewModel
        repliesUserTimelineViewController.viewModel = repliesUserTimelineViewModel
        mediaUserTimelineViewController.viewModel = mediaUserTimelineViewModel
        profileAboutViewController.viewModel = profileAboutViewModel
        super.init()
    }
    
    var viewControllers: [ScrollViewContainer] {
        return [
            postUserTimelineViewController,
            repliesUserTimelineViewController,
            mediaUserTimelineViewController,
            profileAboutViewController,
        ]
    }
    
    let barItems: [TMBarItemable] = {
        let items = [
            TMBarItem(title: L10n.Scene.Profile.SegmentedControl.posts),
            TMBarItem(title: "Posts and Replies"),      // TODO: i18n
            TMBarItem(title: L10n.Scene.Profile.SegmentedControl.media),
            TMBarItem(title: "About"),
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

// MARK: - TMBarDataSource
extension ProfilePagingViewModel: TMBarDataSource {
    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        return barItems[index]
    }
}
