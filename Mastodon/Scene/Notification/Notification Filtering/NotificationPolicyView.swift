// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK
import SwiftUI

private typealias FilterAction = Mastodon.Entity.NotificationPolicy
    .NotificationFilterAction

extension VerticalAlignment {
    enum MenuAlign: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.top]
        }
    }
    
    static let menuAlign = VerticalAlignment(MenuAlign.self)
}

extension HorizontalAlignment {
    enum MenuAlign: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.trailing]
        }
    }
    
    static let menuAlign = HorizontalAlignment(MenuAlign.self)
}

extension VerticalAlignment {
    enum ToggleAlign: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[.top]
        }
    }
    
    static let toggleAlign = VerticalAlignment(ToggleAlign.self)
    
    enum ButtonAlign: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }
    
    static let buttonAlign = VerticalAlignment(ButtonAlign.self)
}

struct NotificationPolicyView: View {
    @Namespace private var menuAnimation
    @StateObject var viewModel: NotificationPolicyViewModel
    @State var menuAnchor: CGPoint?
    @State var readyToShowMenu: Bool = false
    
    private let mainViewPositionPrefKey = "mainView"
    private let menuPositionPrefKey = "menu"

    var body: some View {
        
        mainView()
            .overlay {
                ReferencePointReader(id: mainViewPositionPrefKey, referencePoint: .leadingTop)
            }
            .alignmentGuide(HorizontalAlignment.menuAlign) { d in
                
                guard let menuAnchor else { return d[HorizontalAlignment.center] }
                
                return menuAnchor.x
            }
            .alignmentGuide(VerticalAlignment.menuAlign) { d in
                guard let menuAnchor else { return d[HorizontalAlignment.center] }
                return menuAnchor.y
            }
            .overlay(alignment: Alignment(horizontal: .menuAlign, vertical: .menuAlign)) {
                if readyToShowMenu, let menuItem = viewModel.isShowingMenu {
                    menu(for: menuItem)
                        .alignmentGuide(HorizontalAlignment.menuAlign) { d in
                            return d[HorizontalAlignment.trailing]
                        }
                        .alignmentGuide(VerticalAlignment.menuAlign) { d in
                            return d[VerticalAlignment.center]
                        }
                }
            }
            .onDisappear {
                Task {
                    let updatedPolicy = try await viewModel.saveChanges()
                    viewModel.didDismissView?(updatedPolicy)
                }
            }
            .onPreferenceChange(PositionKey.self) { preferences in
                menuAnchor = preferences.deltaFrom(mainViewPositionPrefKey, to: menuPositionPrefKey)
                let canShowMenuNow = menuAnchor != nil
                if canShowMenuNow != readyToShowMenu {
                    Task { @MainActor in
                        withAnimation {
                            readyToShowMenu = menuAnchor != nil
                        }
                    }
                }
            }
    }
    
    @ViewBuilder func mainView() -> some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
            
            // Settings table
            VStack() {
                Spacer()
                    .frame(height: 40)
                List {
                    ForEach(viewModel.sections, id: \.self) { section in
                        Section(
                            header:
                                Text(section.headerText).font(.title2).fixedSize()
                        ) {
                            ForEach(section.items, id: \.self) { policyItem in
                                rowView(policyItem)
                            }
                        }
                        .textCase(nil)
                    }
                }
                .listStyle(.insetGrouped)
                
                Spacer()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            
            // Dismiss button
            Button {
                viewModel.dismissView?()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .frame(width: 45, height: 45)
                    .font(.title)
                    .foregroundStyle(Color.secondary)
            }
            .padding()
        }
    }

    @ViewBuilder func rowView(
        _ settingType: NotificationPolicyViewModel.NotificationFilterItem
    ) -> some View {

        let controlAlignment = verticalAlignmentForControl(settingType)
        HStack(alignment: controlAlignment) {
            // title and subtitle
            VStack(alignment: .leading) {
                Text(settingType.title)
                    .multilineTextAlignment(.leading)
                    .fixedSize()
                    .font(.headline)
                    .alignmentGuide(controlAlignment) { d in
                        switch controlAlignment {
                        case .buttonAlign:
                            return d[VerticalAlignment.center]
                        case .toggleAlign:
                            return d[.top]
                        default:
                            return d[.top]
                        }
                    }
                Text(settingType.subtitle)
                    .multilineTextAlignment(.leading)
                    .font(.subheadline)
            }
            .accessibilityElement(children: .combine)
            
            Spacer()

            // menu or toggle
            control(settingType)
                .fixedSize()
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder func control(_ settingType: NotificationPolicyViewModel.NotificationFilterItem) -> some View {
        // the control
        switch settingType {
        case .notFollowing, .notFollowers, .newAccounts, .privateMentions,
                .limitedAccounts:
            Button {
                if viewModel.isShowingMenu == nil {
                    viewModel.isShowingMenu = settingType
                } else {
                    viewModel.isShowingMenu = nil
                }
            } label: {
                HStack {
                    Text(viewModel.value(forItem: settingType).displayTitle)
                    Image(systemName: "chevron.up.chevron.down")
                }
            }
            .tint(Asset.Colors.Brand.blurple.swiftUIColor)
            .fixedSize()
            .alignmentGuide(.buttonAlign) { d in return d[VerticalAlignment.center] }
            .transition(.identity)
            .overlay {
                if settingType == viewModel.isShowingMenu {
                    ReferencePointReader(id: menuPositionPrefKey, referencePoint: .trailingCenter)
                }
            }
        case .adminReports, .adminSignups:
            Toggle(
                isOn: Binding(
                    get: {
                        viewModel.value(forItem: settingType) == .accept
                    },
                    set: {
                        viewModel.setValue(
                            $0 ? .accept : .filter, forItem: settingType)
                    })
            ) {}
                .tint(Asset.Colors.Brand.blurple.swiftUIColor)
                .fixedSize()
                .alignmentGuide(.toggleAlign) { d in d[.top] }
        }
    }
    
    func verticalAlignmentForControl(_ settingType: NotificationPolicyViewModel.NotificationFilterItem) -> VerticalAlignment {
        switch settingType {
        case .notFollowing, .notFollowers, .newAccounts, .privateMentions, .limitedAccounts:
                .buttonAlign
        case .adminReports, .adminSignups:
                .toggleAlign
        }
    }
}

extension NotificationPolicyView {
    @ViewBuilder func menu(for filterItem: NotificationPolicyViewModel.NotificationFilterItem) -> some View {
        
        VStack(alignment: .leading) {
            ForEach([FilterAction.accept, .filter, .drop], id: \.self) { option in
                HStack(alignment: .top, spacing: 0) {
                    let checkmarkWidth: CGFloat = 25
                    if viewModel.value(forItem: filterItem) == option {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .frame(width: checkmarkWidth, height: checkmarkWidth)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: checkmarkWidth, height: checkmarkWidth)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(option.displayTitle)
                        Text(option.displaySubtitle)
                            .font(.caption2)
                    }
                }
                .padding(7)
                .fixedSize(horizontal: false, vertical: true)
                .onTapGesture {
                    updateSelectedOption(option, for: filterItem)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAction {
                    updateSelectedOption(option, for: filterItem)
                }
                
                if option != .drop {
                    Spacer()
                        .frame(height: 0.5)
                        .frame(maxWidth: .infinity)
                        .background(SeparatorShapeStyle())
                }
            }
        }
        .frame(width: 250)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(radius: 5)
        }
    }
    
    fileprivate func updateSelectedOption(_ option: FilterAction, for filterItem: NotificationPolicyViewModel.NotificationFilterItem) {
        if viewModel.value(forItem: filterItem) != option {
            viewModel.setValue(option, forItem: filterItem)
        }
        viewModel.isShowingMenu = nil
    }
}

@MainActor
class NotificationPolicyViewModel: ObservableObject {
    
    let sections: [NotificationPolicyViewModel.NotificationFilterSection]

    let originalRegularSettings: NotificationFilterSettings
    let originalAdminSettings: AdminNotificationFilterSettings?

    var dismissView: (() -> Void)?
    var didDismissView: ((Mastodon.Entity.NotificationPolicy?) -> Void)?

    @Published var isShowingMenu: NotificationFilterItem?
    @Published var regularFilterSettings: NotificationFilterSettings
    @Published var adminFilterSettings: AdminNotificationFilterSettings?

    var hasUnsavedChangesToRegularSettings: Bool {
        return regularFilterSettings != originalRegularSettings
    }

    var hasUnsavedChangesToAdminSettings: Bool {
        return adminFilterSettings != originalAdminSettings
    }

    init(
        _ regularSettings: NotificationFilterSettings,
        adminSettings: AdminNotificationFilterSettings?
    ) async {
        self.originalRegularSettings = regularSettings
        self.regularFilterSettings = regularSettings
        self.originalAdminSettings = adminSettings
        self.adminFilterSettings = adminSettings

        self.sections = [.main, adminSettings != nil ? .admin : nil].compactMap { $0 }
    }

    fileprivate func value(forItem item: NotificationFilterItem) -> FilterAction
    {
        switch item {
        case .notFollowing:
            return regularFilterSettings.forNotFollowing
        case .notFollowers:
            return regularFilterSettings.forNotFollowers
        case .newAccounts:
            return regularFilterSettings.forNewAccounts
        case .privateMentions:
            return regularFilterSettings.forPrivateMentions
        case .limitedAccounts:
            return regularFilterSettings.forLimitedAccounts
        case .adminReports:
            return adminFilterSettings?.forReports ?? .drop
        case .adminSignups:
            return adminFilterSettings?.forSignups ?? .drop
        }
    }

    fileprivate func setValue(
        _ value: FilterAction, forItem item: NotificationFilterItem
    ) {
        switch item {
        case .notFollowing:
            regularFilterSettings = NotificationFilterSettings(
                forNotFollowing: value,
                forNotFollowers: regularFilterSettings.forNotFollowers,
                forNewAccounts: regularFilterSettings.forNewAccounts,
                forPrivateMentions: regularFilterSettings.forPrivateMentions,
                forLimitedAccounts: regularFilterSettings.forLimitedAccounts)
        case .notFollowers:
            regularFilterSettings = NotificationFilterSettings(
                forNotFollowing: regularFilterSettings.forNotFollowing,
                forNotFollowers: value,
                forNewAccounts: regularFilterSettings.forNewAccounts,
                forPrivateMentions: regularFilterSettings.forPrivateMentions,
                forLimitedAccounts: regularFilterSettings.forLimitedAccounts)
        case .newAccounts:
            regularFilterSettings = NotificationFilterSettings(
                forNotFollowing: regularFilterSettings.forNotFollowing,
                forNotFollowers: regularFilterSettings.forNotFollowers,
                forNewAccounts: value,
                forPrivateMentions: regularFilterSettings.forPrivateMentions,
                forLimitedAccounts: regularFilterSettings.forLimitedAccounts)
        case .privateMentions:
            regularFilterSettings = NotificationFilterSettings(
                forNotFollowing: regularFilterSettings.forNotFollowing,
                forNotFollowers: regularFilterSettings.forNotFollowers,
                forNewAccounts: regularFilterSettings.forNewAccounts,
                forPrivateMentions: value,
                forLimitedAccounts: regularFilterSettings.forLimitedAccounts)
        case .limitedAccounts:
            regularFilterSettings = NotificationFilterSettings(
                forNotFollowing: regularFilterSettings.forNotFollowing,
                forNotFollowers: regularFilterSettings.forNotFollowers,
                forNewAccounts: regularFilterSettings.forNewAccounts,
                forPrivateMentions: regularFilterSettings.forPrivateMentions,
                forLimitedAccounts: value)

        case .adminReports:
            guard let adminFilterSettings else { return }
            self.adminFilterSettings = AdminNotificationFilterSettings(
                forReports: value,
                forSignups: adminFilterSettings.forSignups)
        case .adminSignups:
            guard let adminFilterSettings else { return }
            self.adminFilterSettings = AdminNotificationFilterSettings(
                forReports: adminFilterSettings.forReports,
                forSignups: value)
        }
    }

    func saveChanges() async throws -> Mastodon.Entity.NotificationPolicy? {
        guard
            let authenticationBox = AuthenticationServiceProvider.shared
                .currentActiveUser.value
        else { return nil }

        if let adminFilterSettings, hasUnsavedChangesToAdminSettings {
            do {
                try await BodegaPersistence.Notifications.updatePreferences(
                    adminFilterSettings, for: authenticationBox)
            } catch {}
        }

        if hasUnsavedChangesToRegularSettings {
            let updatedPolicy = try await APIService.shared
                .updateNotificationPolicy(
                    authenticationBox: authenticationBox,
                    forNotFollowing: value(forItem: .notFollowing),
                    forNotFollowers: value(forItem: .notFollowers),
                    forNewAccounts: value(forItem: .newAccounts),
                    forPrivateMentions: value(forItem: .privateMentions),
                    forLimitedAccounts: value(forItem: .limitedAccounts)
                ).value
            return updatedPolicy
        } else {
            return nil
        }
    }
}

extension NotificationPolicyViewModel {
    fileprivate func binding(for settingItem: NotificationFilterItem)
        -> Binding<FilterAction>
    {
        return Binding(
            get: { [weak self] in
                self?.value(forItem: settingItem) ?? ._other("unset")
            }, set: { [weak self] in self?.setValue($0, forItem: settingItem) })
    }
}

extension NotificationPolicyViewModel {
    enum NotificationFilterSection: Hashable {
        case main
        case admin

        var items: [NotificationFilterItem] {
            switch self {
            case .main:
                return [
                    .notFollowing, .notFollowers, .newAccounts,
                    .privateMentions, .limitedAccounts,
                ]
            case .admin:
                return [.adminReports, .adminSignups]
            }
        }

        var headerText: String {
            switch self {
            case .main:
                L10n.Scene.Notification.Policy.title
            case .admin:
                L10n.Scene.Notification.AdminFilter.title
            }
        }
    }

    enum NotificationFilterItem: Hashable {
        case notFollowing
        case notFollowers
        case newAccounts
        case privateMentions
        case limitedAccounts

        case adminReports
        case adminSignups

        static let regularOptions = [
            Self.notFollowing, .notFollowers, .newAccounts, .privateMentions,
            .limitedAccounts,
        ]
        static let adminOptions = [Self.adminReports, .adminSignups]

        var title: String {
            switch self {
            case .notFollowing:
                return L10n.Scene.Notification.Policy.NotFollowing.title
            case .notFollowers:
                return L10n.Scene.Notification.Policy.NoFollower.title
            case .newAccounts:
                return L10n.Scene.Notification.Policy.NewAccount.title
            case .privateMentions:
                return L10n.Scene.Notification.Policy.PrivateMentions.title
            case .limitedAccounts:
                return L10n.Scene.Notification.Policy.ModeratedAccounts.title

            case .adminReports:
                return L10n.Scene.Notification.AdminFilter.Reports.title
            case .adminSignups:
                return L10n.Scene.Notification.AdminFilter.Signups.title
            }
        }

        var subtitle: String {
            switch self {
            case .notFollowing:
                return L10n.Scene.Notification.Policy.NotFollowing.subtitle
            case .notFollowers:
                return L10n.Scene.Notification.Policy.NoFollower.subtitle
            case .newAccounts:
                return L10n.Scene.Notification.Policy.NewAccount.subtitle
            case .privateMentions:
                return L10n.Scene.Notification.Policy.PrivateMentions.subtitle
            case .limitedAccounts:
                return L10n.Scene.Notification.Policy.ModeratedAccounts.subtitle

            case .adminReports:
                return L10n.Scene.Notification.AdminFilter.Reports.subtitle
            case .adminSignups:
                return L10n.Scene.Notification.AdminFilter.Signups.subtitle
            }
        }
    }
}

struct NotificationFilterSettings: Codable, Equatable {
    let forNotFollowing:
        Mastodon.Entity.NotificationPolicy.NotificationFilterAction
    let forNotFollowers:
        Mastodon.Entity.NotificationPolicy.NotificationFilterAction
    let forNewAccounts:
        Mastodon.Entity.NotificationPolicy.NotificationFilterAction
    let forPrivateMentions:
        Mastodon.Entity.NotificationPolicy.NotificationFilterAction
    let forLimitedAccounts:
        Mastodon.Entity.NotificationPolicy.NotificationFilterAction
}

extension FilterAction {
    var displayTitle: String {
        switch self {
        case .accept:  return L10n.Scene.Notification.Policy.Action.Accept.title
        case .filter:  return L10n.Scene.Notification.Policy.Action.Filter.title
        case .drop:    return L10n.Scene.Notification.Policy.Action.Drop.title
        case ._other(let string): return string
        }
    }
    
    var displaySubtitle: String {
        switch self {
        case .accept:  return L10n.Scene.Notification.Policy.Action.Accept.subtitle
        case .filter:  return L10n.Scene.Notification.Policy.Action.Filter.subtitle
        case .drop:    return L10n.Scene.Notification.Policy.Action.Drop.subtitle
        case ._other: return ""
        }
    }
}
