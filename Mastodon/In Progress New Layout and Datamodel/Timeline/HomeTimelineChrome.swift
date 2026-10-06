// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonLocalization

struct HomeTimelineChrome: ViewModifier {
    @Environment(MastodonTabViewRouter.self) private var tabViewRouter
    @Environment(MastodonNavigationRouter.self) private var navigationRouter
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(currentHomeFeedName ?? "")
            .toolbar {
                if !tabViewRouter.currentTabBarPlacement.isSidebarAvailable {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            homeTimelineFeedPickerContents
                        } label: {
                            Label(L10nLookup.Timeline.FeedMenu.buttonA11yLabel, phosphor: .list)
                        }
                    }
                }

                if tabViewRouter.isHomeTimelineFilterAvailable, let homeTimelineModel = tabViewRouter.homeTimelineModel, homeTimelineModel.timeline == .homeTimeline {
                    ToolbarItem(placement: .topBarTrailing) {
                        HomeFeedFilterButton()
                            .environment(homeTimelineModel)
                    }
                }
                if tabViewRouter.currentTabBarPlacement.isSidebarAvailable {
                    ToolbarItem(placement: .topBarTrailing) {
                        modalComposeButton(diameter: 40)
                    }
                    .sharedBackgroundVisibilityHidden()
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !tabViewRouter.currentTabBarPlacement.isSidebarAvailable {
                    modalComposeButton(diameter: 50)
                }
            }
    }
    
    @ViewBuilder var homeTimelineFeedPickerContents: some View {
        Section {
            feedMenuItem(L10n.Common.Controls.Tabs.home, timeline: .homeTimeline, icon: Image(phosphor: .house))
            if tabViewRouter.isLocalTimelineAvailable {
                feedMenuItem(L10n.Scene.HomeTimeline.TimelineMenu.localCommunity, timeline: .local)
            }
        }
        if !tabViewRouter.lists.isEmpty {
            Section {
                Menu(L10nLookup.Timeline.FeedMenu.customFeeds) {
                    ForEach(tabViewRouter.lists, id: \.self.id) { list in
                        feedMenuItem(list.title, timeline: .list(list.id), icon: Image(phosphor: .rssSimple))
                    }
                }
            }
        }
        if !tabViewRouter.followedHashtags.isEmpty {
            Section {
                Menu(L10n.Scene.HomeTimeline.TimelineMenu.Hashtags.title) {
                    ForEach(tabViewRouter.followedHashtags, id: \.self.name) { hashtag in
                        feedMenuItem("#\(hashtag.name)", timeline: .hashtag(hashtag, includeHeader: false))
                    }
                }
            }
        }
    }
    
    @ViewBuilder func feedMenuItem(_ title: String, timeline: MastodonTimelineType, icon: Image? = nil) -> some View {
        let isSelected = Binding(
            get: { tabViewRouter.homeTimelineModel?.timeline == timeline },
            set: { _ in tabViewRouter.homeTimelineModel?.setTimeline(timeline, navigator: tabViewRouter.navigationRouter(forTab: .home)) }
        )
        if let icon {
            Toggle(isOn: isSelected) { Label(title, icon: icon) }
        } else {
            Toggle(title, isOn: isSelected)
        }
    }
    
    var currentHomeFeedName: String? {
        guard let timeline = tabViewRouter.homeTimelineModel?.timeline else { return nil }
        switch timeline {
        case .homeTimeline:
            return L10n.Common.Controls.Tabs.home
        case .local:
            return L10n.Scene.HomeTimeline.TimelineMenu.localCommunity
        case .list(let listID):
            return tabViewRouter.lists.first(where: { $0.id == listID })?.title
        case .hashtag(let hashtag, _):
            return "#\(hashtag.name)"
            
        default:
            return nil
        }
    }
    
    @ViewBuilder private func modalComposeButton(diameter: CGFloat) -> some View {
        let iconSize = diameter * 0.6
        let navigator = navigationRouter
        if let authBox = AuthenticationObserver.shared.currentActiveUser {
            Button {
                navigator.presentSheet(.modalCompose(.init(authenticationBox: authBox, composeContext: .composeStatus(quoting: nil), destination: .topLevel), nil), afterDeconflictionDelay: false)
            } label: {
                Image(phosphor: .penNib)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .visualEffect({ content, geo in
                        content.offset(x: geo.size.width * 0.04, y: -geo.size.height * 0.04) // compensate for the visual weight of the icon, otherwise it looks off-center
                    })
                    .foregroundStyle(.white)
                    .frame(width: diameter, height: diameter)
                    .background {
                        Circle()
                            .fill(Asset.Colors.accent.swiftUIColor)
                    }
            }
            .padding()
            .accessibilityLabel(L10nLookup.MastodonMenuAction.Navigation.compose)
        }
    }
}

struct HomeFeedFilterButton: View {
    @Environment(TimelineListViewModel.self) var viewModel
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    
    var body: some View {
        if voiceOverEnabled {
            Menu {
                ActivityFilterToggleRows(showQuotesToggle: true)
            } label: {
                buttonLabel
            }
        } else {
            Button {
                viewModel.isPresentingActivityFilter = !viewModel.isPresentingActivityFilter
            } label: {
                buttonLabel
            }
            .popover(isPresented: Binding<Bool>(
                get: { viewModel.isPresentingActivityFilter },
                set: { isPresented in viewModel.isPresentingActivityFilter = isPresented }
            )) {
                ActivityFilterToggles(showQuotesToggle: true)
                    .environment(viewModel)
            }
        }
    }
    
    private var buttonLabel: some View {
        Label(L10nLookup.Timeline.FeedFilter.buttonA11yLabel, phosphor: .slidersHorizontal)
    }
}
