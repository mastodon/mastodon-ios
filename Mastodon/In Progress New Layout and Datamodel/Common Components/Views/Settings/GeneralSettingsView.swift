// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonLocalization
import MastodonUI

struct GeneralSettingsSection: Hashable {
    let type: GeneralSettingsSectionType
    let entries: [GeneralSetting]
}

enum GeneralSettingsSectionType: Hashable {
    case appearance
    case askBefore
    case design
    case language
    case links

    var sectionTitle: String {
        switch self {
        case .appearance:
            return L10n.Scene.Settings.General.Appearance.sectionTitle
        case .askBefore:
            return L10n.Scene.Settings.General.AskBefore.sectionTitle
        case .design:
            return L10n.Scene.Settings.General.Design.sectionTitle
        case .language:
            return L10n.Scene.Settings.General.Language.sectionTitle
        case .links:
            return L10n.Scene.Settings.General.Links.sectionTitle
        }
    }
}

enum GeneralSetting: Hashable {

    case appearance(Appearance)
    case askBefore(AskBefore)
    case design(Design)
    case language(Language)
    case openLinksIn(OpenLinksIn)

    enum Appearance: Int, CaseIterable {
        case light = 1
        case dark = 2
        case system = 0

        var title: String {
            switch self {
            case .light:
                return L10n.Scene.Settings.General.Appearance.light
            case .dark:
                return L10n.Scene.Settings.General.Appearance.dark
            case .system:
                return L10n.Scene.Settings.General.Appearance.system
            }
        }

        var interfaceStyle: UIUserInterfaceStyle {
            .init(rawValue: rawValue) ?? .unspecified
        }
    }
    
    enum AskBefore: Hashable {
        case postingWithoutAltText
        case unfollowingSomeone
        case boostingAPost
        case deletingAPost
        
        var title: String {
            switch self {
            case .postingWithoutAltText:
                return L10n.Scene.Settings.General.AskBefore.postingWithoutAltText
            case .unfollowingSomeone:
                return L10n.Scene.Settings.General.AskBefore.unfollowingSomeone
            case .boostingAPost:
                return L10n.Scene.Settings.General.AskBefore.boostingAPost
            case .deletingAPost:
                return L10n.Scene.Settings.General.AskBefore.deletingAPost

            }
        }
    }

    enum Design: Hashable {
        case showAnimations

        var title: String {
            switch self {
            case .showAnimations:
                return L10n.Scene.Settings.General.Design.showAnimations
            }
        }
    }
    
    enum Language: Hashable {
        case defaultPostLanguage
        
        var title: String {
            switch self {
            case .defaultPostLanguage:
                return L10n.Scene.Settings.General.Language.defaultPostLanguage
            }
        }
    }

    enum OpenLinksIn: Hashable, CaseIterable {
        case mastodon
        case browser

        var title: String {
            switch self {
            case .mastodon:
                return L10n.Scene.Settings.General.Links.openInMastodon
            case .browser:
                return L10n.Scene.Settings.General.Links.openInBrowser
            }
        }
    }
}

struct GeneralSettingsView: View {
    @Environment(GeneralSettingsViewModel.self) private var viewModel
    @Environment(MastodonNavigationRouter.self) private var navigator
    
    let sections = [
        GeneralSettingsSection(type: .appearance, entries: [
            .appearance(.light),
            .appearance(.dark),
            .appearance(.system)
        ]),
        GeneralSettingsSection(type: .askBefore, entries: [
            .askBefore(.postingWithoutAltText),
            .askBefore(.unfollowingSomeone),
            .askBefore(.boostingAPost),
            .askBefore(.deletingAPost)
        ]),
        GeneralSettingsSection(type: .design, entries: [
            .design(.showAnimations)
        ]),
        GeneralSettingsSection(type: .language, entries: [
            .language(.defaultPostLanguage)
        ]),
        GeneralSettingsSection(type: .links, entries: [
            .openLinksIn(.mastodon),
            .openLinksIn(.browser),
        ])
    ]
    
    var body: some View {
        Form {
            ForEach(sections, id: \.self.type) { section in
                Section(section.type.sectionTitle) {
                    ForEach(section.entries, id: \.self) { entry in
                        switch entry {
                        case .appearance(let appearance):
                            SelectionRow(label: appearance.title, isSelected: viewModel.appearanceBinding(appearance), onSelect: nil)
                            
                        case .askBefore(let askBefore):
                            ToggleRow(label: askBefore.title, isOn: viewModel.askBeforeBinding(askBefore))
                            
                        case .design(let design):
                            ToggleRow(label: design.title, isOn: viewModel.designBinding(design))
                            
                        case .language(let language):
                            NavigationRow(label: language.title, sublabel: viewModel.defaultPostLanguageName)
                                .onTapGesture {
                                    navigator.push(.settings(.languageSelection))
                                }
                        case .openLinksIn(let openLinksIn):
                            SelectionRow(label: openLinksIn.title, isSelected: viewModel.openLinksInBinding(openLinksIn), onSelect: nil)
                        }
                    }
                }
            }
        }
        .navigationTitle(L10n.Scene.Settings.General.title)
    }
}

struct SelectionRow: View {
    let label: String
    @Binding var isSelected: Bool
    let onSelect: (()->())?
    
    var body: some View {
        HStack {
            Text(label)
            if isSelected {
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundStyle(Asset.Colors.accent.swiftUIColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isSelected = true
            onSelect?()
        }
    }
    
}

struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(label, isOn: $isOn)
    }
}

struct NavigationRow: View {
    let label: String
    let sublabel: String?
    @Environment(\.isEnabled) var enabled
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(enabled ? .primary : .secondary)
            Spacer()
            if let sublabel {
                Text(sublabel)
                    .font(.subheadline)
                    .foregroundStyle(enabled ? .secondary : .tertiary)
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(enabled ? .secondary : .tertiary)
        }
        .contentShape(Rectangle())
    }
}

@MainActor
@Observable class GeneralSettingsViewModel {
    var selectedAppearence: GeneralSetting.Appearance {
        didSet {
            UserDefaults.shared.customUserInterfaceStyle = selectedAppearence.interfaceStyle
        }
    }
    var playAnimations: Bool {
        didSet {
            UserDefaults.shared.preferredStaticAvatar = !playAnimations
            UserDefaults.shared.preferredStaticEmoji = !playAnimations
        }
    }
    var selectedOpenLinks: GeneralSetting.OpenLinksIn {
        didSet {
            switch selectedOpenLinks {
            case .mastodon:
                UserDefaults.shared.preferredUsingDefaultBrowser = false
            case .browser:
                UserDefaults.shared.preferredUsingDefaultBrowser = true
            }
        }
    }
    var askBeforePostingWithoutAltText: Bool {
        didSet {
            UserDefaults.shared.askBeforePostingWithoutAltText = askBeforePostingWithoutAltText
        }
    }
    var askBeforeUnfollowingSomeone: Bool {
        didSet {
            UserDefaults.shared.askBeforeUnfollowingSomeone = askBeforeUnfollowingSomeone
        }
    }
    var askBeforeBoostingAPost: Bool {
        didSet {
            UserDefaults.shared.askBeforeBoostingAPost = askBeforeBoostingAPost
        }
    }
    var askBeforeDeletingAPost: Bool {
        didSet {
            UserDefaults.shared.askBeforeDeletingAPost = askBeforeDeletingAPost
        }
    }
    var defaultPostLanguage: String {
        didSet {
            UserDefaults.shared.defaultPostLanguage = defaultPostLanguage
        }
    }
    var defaultPostLanguageName: String {
        LanguagePicker.availableLanguages()
            .first { $0.localeId == defaultPostLanguage }?
            .endonym ?? defaultPostLanguage
    }
    
    init() {
        selectedAppearence = GeneralSetting.Appearance(rawValue: UserDefaults.shared.customUserInterfaceStyle.rawValue) ?? .system
        selectedOpenLinks = {
            if UserDefaults.shared.preferredUsingDefaultBrowser {
                return .browser
            } else {
                return .mastodon
            }
        }()
        playAnimations = (UserDefaults.shared.preferredStaticAvatar == false && UserDefaults.shared.preferredStaticEmoji == false)
        askBeforePostingWithoutAltText = UserDefaults.shared.askBeforePostingWithoutAltText
        askBeforeUnfollowingSomeone = UserDefaults.shared.askBeforeUnfollowingSomeone
        askBeforeBoostingAPost = UserDefaults.shared.askBeforeBoostingAPost
        askBeforeDeletingAPost = UserDefaults.shared.askBeforeDeletingAPost
        defaultPostLanguage = UserDefaults.shared.defaultPostLanguage
    }
    
    func appearanceBinding(_ appearance: GeneralSetting.Appearance) -> Binding<Bool> {
        Binding<Bool>(get: { self.selectedAppearence == appearance }, set: { newValue in if newValue { self.selectedAppearence = appearance } })
    }
    
    func askBeforeBinding(_ askBefore: GeneralSetting.AskBefore) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                switch askBefore {
                case .postingWithoutAltText:
                    self.askBeforePostingWithoutAltText
                case .unfollowingSomeone:
                    self.askBeforeUnfollowingSomeone
                case .boostingAPost:
                    self.askBeforeBoostingAPost
                case .deletingAPost:
                    self.askBeforeDeletingAPost
                }
            },
            set: { newValue in
                switch askBefore {
                case .postingWithoutAltText:
                    self.askBeforePostingWithoutAltText = newValue
                case .unfollowingSomeone:
                    self.askBeforeUnfollowingSomeone = newValue
                case .boostingAPost:
                    self.askBeforeBoostingAPost = newValue
                case .deletingAPost:
                    self.askBeforeDeletingAPost = newValue
                }
            }
        )
    }
    
    func designBinding(_ design: GeneralSetting.Design) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                switch design {
                case .showAnimations:
                    return self.playAnimations
                }
            },
            set: { newValue in
                switch design {
                case .showAnimations:
                    self.playAnimations = newValue
                }
            }
        )
    }
    
    func openLinksInBinding(_ openLinksIn: GeneralSetting.OpenLinksIn) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                self.selectedOpenLinks == openLinksIn
            },
            set: { newValue in
                if newValue { self.selectedOpenLinks = openLinksIn }
            }
        )
    }
}
