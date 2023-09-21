//
//  ProfilePagingViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-29.
//

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
    
    
}
