//
//  ProfilePagingViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

import os.log
import UIKit
import MastodonAsset
import MastodonLocalization
import TabBarPager

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
    
    var viewControllers: [UIViewController & TabBarPage] {
        return [
            postUserTimelineViewController,
            repliesUserTimelineViewController,
            mediaUserTimelineViewController,
            profileAboutViewController,
        ]
    }
    
//    let barItems: [TMBarItemable] = {
//        let items = [
//            TMBarItem(title: L10n.Scene.Profile.SegmentedControl.posts),
//            TMBarItem(title: L10n.Scene.Profile.SegmentedControl.postsAndReplies),
//            TMBarItem(title: L10n.Scene.Profile.SegmentedControl.media),
//            TMBarItem(title: L10n.Scene.Profile.SegmentedControl.about),
//        ]
//        return items
//    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

//// MARK: - PageboyViewControllerDataSource
//extension ProfilePagingViewModel: PageboyViewControllerDataSource {
//
//    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
//        return viewControllers.count
//    }
//
//    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
//        return viewControllers[index]
//    }
//
//    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
//        return .first
//    }
//
//}
//
//// MARK: - TMBarDataSource
//extension ProfilePagingViewModel: TMBarDataSource {
//    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
//        return barItems[index]
//    }
//}
