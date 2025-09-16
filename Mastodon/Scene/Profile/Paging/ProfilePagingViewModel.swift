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
    
    let postUserTimelineViewController: UIViewController & TabBarPage
    let repliesUserTimelineViewController: UIViewController & TabBarPage
    let mediaUserTimelineViewController: UIViewController & TabBarPage
    let profileAboutViewController = ProfileAboutViewController()
    
    // input
    @Published var needsSetupBottomShadow = true
    
    init(
        postsUserTimelineViewModel: UserTimelineViewModel,
        repliesUserTimelineViewModel: UserTimelineViewModel,
        mediaUserTimelineViewModel: UserTimelineViewModel,
        profileAboutViewModel: ProfileAboutViewModel
    ) {
        if let user = postsUserTimelineViewModel.userIdentifier?.userID {
            postUserTimelineViewController = TimelineListViewController(.profilePosts(tabTitle: L10n.Scene.Profile.SegmentedControl.posts, userID: user, queryFilter: TimelineQueryFilter(excludeReplies: true)))
            repliesUserTimelineViewController = TimelineListViewController(.profilePosts(tabTitle: L10n.Scene.Profile.SegmentedControl.postsAndReplies, userID: user, queryFilter: TimelineQueryFilter(excludeReplies: false, excludeReblogs: true)))
            mediaUserTimelineViewController = TimelineListViewController(.profilePosts(tabTitle: L10n.Scene.Profile.SegmentedControl.media, userID: user, queryFilter: TimelineQueryFilter(onlyMedia: true)))
        } else {
            // TODO: remove these placeholders for error case when the profile view has been rewritten
            postUserTimelineViewController = TimelineListViewController(.trendingPosts)
            repliesUserTimelineViewController = TimelineListViewController(.trendingPosts)
            mediaUserTimelineViewController = TimelineListViewController(.trendingPosts)
        }
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
