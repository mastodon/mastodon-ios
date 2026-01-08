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

@MainActor
final class ProfilePagingViewModel: NSObject {
    
    let postUserTimelineViewController: UIViewController & TabBarPage
    let repliesUserTimelineViewController: UIViewController & TabBarPage
    let mediaUserTimelineViewController: UIViewController & TabBarPage
    let profileAboutViewController = ProfileAboutViewController()
    
    // input
    @Published var needsSetupBottomShadow = true
    
    init(
        profileAboutViewModel: ProfileAboutViewModel
    ) {
        let user = profileAboutViewModel.account.id
        postUserTimelineViewController = TimelineListViewController(.profilePosts(tabTitle: L10n.Scene.Profile.SegmentedControl.posts, userID: user, queryFilter: TimelineQueryFilter(.userPosts)))
        let repliesIncludedFilter = TimelineQueryFilter(.userPosts)
        repliesIncludedFilter.excludeReplies = false
        repliesIncludedFilter.excludeReblogs = true
        repliesUserTimelineViewController = TimelineListViewController(.profilePosts(tabTitle: L10n.Scene.Profile.SegmentedControl.postsAndReplies, userID: user, queryFilter: repliesIncludedFilter))
        mediaUserTimelineViewController = TimelineListViewController(.profilePosts(tabTitle: L10n.Scene.Profile.SegmentedControl.media, userID: user, queryFilter: TimelineQueryFilter(.mediaOnly)))
        
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

// MARK: Temporary Hack (until we replace profile view)

extension TimelineListViewController: TabBarPage {
    var pageScrollView: UIScrollView {
        return UIScrollView()
    }
}
