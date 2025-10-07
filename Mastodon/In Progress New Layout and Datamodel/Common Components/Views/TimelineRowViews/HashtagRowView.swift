// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonLocalization
import MastodonSDK
import MastodonUI
import AuthenticationServices
import MastodonCore

struct HashtagRowView: View {
    
    @Environment(HashtagRowViewModel.self) var viewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: tinySpacing) {
                Text("#\(viewModel.entity.name)")
                    .foregroundStyle(.primary)
                
                Text(L10n.Plural.peopleTalking(viewModel.entity.talkingPeopleCount ?? 0))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            WrappedLineChartView(tag: viewModel.entity)
                .frame(width: 50, height: 26)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct HashtagHeaderView: View {
    
    @Environment(HashtagRowViewModel.self) var viewModel
    @State var isUpdating: Bool = false
    
    var body: some View {
        HStack {
            // HASHTAG AND STATS
            VStack(alignment: .leading, spacing: tinySpacing) {
                Text("#\(viewModel.entity.name)")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .fixedSize()

                HStack(alignment: .bottom, spacing: doublePadding) {
                    ForEach(StatType.allCases, id: \.self) { stat in
                        statsView(stat)
                    }
                }
            }
            
            Spacer()

            // GRAPH AND FOLLOW BUTTON
            VStack(alignment: .trailing) {
                if viewModel.entity.history != nil {
                    WrappedLineChartView(tag: viewModel.entity)
                        .frame(width: 100, height: 26)
                        .accessibilityHidden(true)
                }
                Spacer()
                if let isFollowing = viewModel.entity.following {
                    buttonType.button {
                        guard let user = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
                        isUpdating = true
                        Task {
                            if isFollowing {
                                if let updated = try? await APIService.shared.unfollowTag(
                                    for: viewModel.entity.name,
                                    authenticationBox: user
                                ).value {
                                    FeedCoordinator.shared.publishUpdate(.hashtag(updated))
                                }
                            } else {
                                if let updated = try? await APIService.shared.followTag(
                                    for: viewModel.entity.name,
                                    authenticationBox: user
                                ).value {
                                    FeedCoordinator.shared.publishUpdate(.hashtag(updated))
                                }
                            }
                            isUpdating = false
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
    
    var buttonType: RelationshipButtonType {
        guard !isUpdating else { return .updating }
        guard let isFollowing = viewModel.entity.following else { return .updating }
        return isFollowing ? .iFollowThem(theyFollowMe: false) : .iDoNotFollowThem(theyFollowMe: false, theirAccountIsLocked: false)
    }
    
    @ViewBuilder func statsView(_ stat: StatType) -> some View {
        VStack(spacing: 0) {
            Text(MastodonMetricFormatter().string(from: statCount(stat)) ?? "-")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(stat.label)
                .font(.footnote)
                .lineLimit(1)
                .fixedSize()
        }
    }
    
    func statCount(_ stat: StatType) -> Int {
        switch stat {
        case .postCount:
            return (viewModel.entity.history ?? []).reduce(0) { res, acc in
                        res + (Int(acc.uses) ?? 0)
                    }
        case .participantCount:
            return (viewModel.entity.history ?? []).reduce(0) { res, acc in
                        res + (Int(acc.accounts) ?? 0)
                    }
        case .postsToday:
            return Int(viewModel.entity.history?.first?.uses ?? "0") ?? 0
        }
    }
    
    enum StatType: CaseIterable {
        case postCount
        case participantCount
        case postsToday
        
        var label: String {
            switch self {
            case .postCount:
                L10n.Scene.FollowedTags.Header.posts
            case .participantCount:
                L10n.Scene.FollowedTags.Header.participants
            case .postsToday:
                L10n.Scene.FollowedTags.Header.postsToday
            }
        }
    }
}

struct WrappedLineChartView: UIViewRepresentable {
    typealias UIViewType = LineChartView
    let tag: Mastodon.Entity.Tag
    
    func makeUIView(context: Context) -> LineChartView {
        let view = LineChartView()
        view.data = points
        return view
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
        uiView.data = points
    }
    
    var points: [CGFloat] {
        (tag.history ?? [])
            .sorted(by: { $0.day < $1.day })  // latest last
            .map { entry in
                guard let point = Int(entry.accounts) else {
                    return .zero
                }
                return CGFloat(point)
            }
    }
    
}
