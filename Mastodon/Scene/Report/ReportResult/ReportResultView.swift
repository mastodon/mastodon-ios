//
//  ReportResultView.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-11.
//

import UIKit
import SwiftUI
import MastodonSDK
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization
import CoreDataStack

struct ReportResultView: View {
    
    @ObservedObject var viewModel: ReportResultViewModel
    
    var avatarView: some View {
        HStack {
            Spacer()
            ZStack {
                AnimatedImage(imageURL: viewModel.avatarURL)
                    .frame(width: 106, height: 106, alignment: .center)
                    .background(Color(UIColor.systemFill))
                    .cornerRadius(27)
                Text(L10n.Scene.Report.reported)
                    .font(Font(FontFamily.Staatliches.regular.font(size: 49) as CTFont))
                    .foregroundColor(Color(Asset.Scene.Report.reportBanner.color))
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: -2, trailing: 10))
                    .background(Color(viewModel.backgroundColor))
                    .cornerRadius(7)
                    .padding(7)
                    .background(Color(Asset.Scene.Report.reportBanner.color))
                    .cornerRadius(12)
                    .rotationEffect(.degrees(-8))
                    .offset(x: 0, y: -5)
            }
            Spacer()
        }
        .padding()
    }
    
    var body: some View {
        ScrollView(.vertical) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.headline)
                        .foregroundColor(Color(Asset.Colors.Label.primary.color))
                        .font(Font(UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 28, weight: .bold)) as CTFont))
                    if viewModel.isReported {
                        avatarView
                        Text(verbatim: L10n.Scene.Report.StepFinal.whileWeReviewThisYouCanTakeActionAgainstUser("@\(viewModel.username)"))
                            .foregroundColor(Color(Asset.Colors.Label.secondary.color))
                            .font(Font(UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 17, weight: .regular)) as CTFont))
                    } else {
                        Text(verbatim: L10n.Scene.Report.StepFinal.whenYouSeeSomethingYouDontLikeOnMastodonYouCanRemoveThePersonFromYourExperience)
                            .foregroundColor(Color(Asset.Colors.Label.secondary.color))
                            .font(Font(UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 17, weight: .regular)) as CTFont))
                    }
                }
                Spacer()
            }
            .padding()
            
            VStack(spacing: 32) {
                // Follow
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Scene.Report.StepFinal.unfollowUser("@\(viewModel.username)"))
                        .font(.headline)
                        .foregroundColor(Color(Asset.Colors.Label.primary.color))
                    ReportActionButton(
                        action: {
                            viewModel.followActionPublisher.send()
                        },
                        title: viewModel.relationshipViewModel.isFollowing ? L10n.Scene.Report.StepFinal.unfollow : L10n.Scene.Report.StepFinal.unfollowed,
                        isBusy: viewModel.isRequestFollow
                    )
                }
                
                // Mute
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Scene.Report.StepFinal.muteUser("@\(viewModel.username)"))
                        .font(.headline)
                        .foregroundColor(Color(Asset.Colors.Label.primary.color))
                    Text(verbatim: L10n.Scene.Report.StepFinal.youWontSeeTheirPostsOrReblogsInYourHomeFeedTheyWontKnowTheyVeBeenMuted)
                        .foregroundColor(Color(Asset.Colors.Label.secondary.color))
                        .font(Font(UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 13, weight: .regular)) as CTFont))
                    ReportActionButton(
                        action: {
                            viewModel.muteActionPublisher.send()
                        },
                        title: viewModel.relationshipViewModel.isMuting ? L10n.Common.Controls.Friendship.muted : L10n.Common.Controls.Friendship.mute,
                        isBusy: viewModel.isRequestMute
                    )
                }
                
                // Block
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Scene.Report.StepFinal.blockUser("@\(viewModel.username)"))
                        .font(.headline)
                        .foregroundColor(Color(Asset.Colors.Label.primary.color))
                    Text(verbatim: L10n.Scene.Report.StepFinal.theyWillNoLongerBeAbleToFollowOrSeeYourPostsButTheyCanSeeIfTheyveBeenBlocked)
                        .foregroundColor(Color(Asset.Colors.Label.secondary.color))
                        .font(Font(UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 13, weight: .regular)) as CTFont))
                    ReportActionButton(
                        action: {
                            viewModel.blockActionPublisher.send()
                        },
                        title: viewModel.relationshipViewModel.isBlocking ? L10n.Common.Controls.Friendship.blocked : L10n.Common.Controls.Friendship.block,
                        isBusy: viewModel.isRequestBlock
                    )
                }
            }
            .padding()
            
            Spacer()
                .frame(minHeight: viewModel.bottomPaddingHeight)
        }
        .background(
            Color(viewModel.backgroundColor)
        )
    }

}

struct ReportActionButton: View {

    var action: () -> Void
    var title: String
    var isBusy: Bool

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                ProgressView()
                    .opacity(isBusy ? 1 : 0)
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color(UIColor.black))
                    .opacity(isBusy ? 0 : 1)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor.white))     // using white for Light & Dark
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }

}

//#if DEBUG
//
//struct ReportResultView_Previews: PreviewProvider {
//
//    static func viewModel(isReported: Bool) -> ReportResultViewModel {
//        let context = AppContext.shared
//        let request = MastodonUser.sortedFetchRequest
//        request.fetchLimit = 1
//
//        let property = MastodonUser.Property(
//            identifier: "1",
//            domain: "domain.com",
//            id: "1",
//            acct: "@user@domain.com",
//            username: "user",
//            displayName: "User",
//            avatar: "",
//            avatarStatic: "",
//            header: "",
//            headerStatic: "",
//            note: "",
//            url: "",
//            statusesCount: Int64(100),
//            followingCount: Int64(100),
//            followersCount: Int64(100),
//            locked: false,
//            bot: false,
//            suspended: false,
//            createdAt: Date(),
//            updatedAt: Date(),
//            emojis: [],
//            fields: []
//        )
//        let user = try! context.managedObjectContext.fetch(request).first ?? MastodonUser.insert(into: context.managedObjectContext, property: property)
//
//        return ReportResultViewModel(
//            context: context,
//            authContext: nil,
//            user: .init(objectID: user.objectID),
//            isReported: isReported
//        )
//    }
//    static var previews: some View {
//        Group {
//            NavigationView {
//                ReportResultView(viewModel: viewModel(isReported: true))
//                    .navigationBarTitle(Text(""))
//                    .navigationBarTitleDisplayMode(.inline)
//            }
//            NavigationView {
//                ReportResultView(viewModel: viewModel(isReported: false))
//                    .navigationBarTitle(Text(""))
//                    .navigationBarTitleDisplayMode(.inline)
//            }
//            NavigationView {
//                ReportResultView(viewModel: viewModel(isReported: true))
//                    .navigationBarTitle(Text(""))
//                    .navigationBarTitleDisplayMode(.inline)
//            }
//            .preferredColorScheme(.dark)
//        }
//    }
//    
//}
//
//#endif
