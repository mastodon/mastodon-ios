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
    
    // input
    @Published var needsSetupBottomShadow = true
    
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
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}
