// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import MastodonLocalization
import SwiftUI
import MastodonAsset

public typealias OnLanguageSelected = (String) -> Void

struct LanguagePickerNavigationView: View {

    public init(selectedLanguage: String, onSelect: @escaping OnLanguageSelected) {
        self._selectedLanguage = State(initialValue: selectedLanguage)
        self.onSelect = onSelect
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLanguage: String
    private let onSelect: OnLanguageSelected
    
    var body: some View {
        NavigationView {
            LanguagePicker(selectedLanguage: selectedLanguage) { onSelect($0) }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.Common.Controls.Actions.cancel) {
                            dismiss()
                        }
                    }
                }
                .navigationTitle(L10n.Scene.Compose.Language.title)
                .navigationBarTitleDisplayMode(.inline)
        }.navigationViewStyle(.stack)
    }
}

public struct LanguagePicker: View {

    public init(selectedLanguage: String, onSelect: @escaping OnLanguageSelected) {
        self._selectedLanguage = State(initialValue: selectedLanguage)
        self.onSelect = onSelect
    }
    
    @State private var selectedLanguage: String
    private let onSelect: OnLanguageSelected
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var query = ""
    @State private var languages: [Language] = availableLanguages()
    
    public static func availableLanguages() -> [Language] {
        let locales = Locale.availableIdentifiers.map(Locale.init(identifier:))
        var languages: [String: Language] = [:]

        // these script and variant codes are supported by the server side and are to be kept in list
        // see SUPPORTED_LOCALES in Mastodon source for more details
        let variantMappings = [
            "ms-Arab": "ms-Arab",
            "zh_CN": "zh-CN",
            "zh_HK": "zh-HK",
            "zh_TW": "zh-TW",
        ]

        for locale in locales {
            let code = locale.identifier
            if let endonym = locale.localizedString(forIdentifier: code),
               let exonym = Locale.current.localizedString(forIdentifier: code) {
                if let mappedCode = variantMappings[code] {
                    languages[mappedCode] = Language(endonym: endonym, exonym: exonym, id: mappedCode, localeId: code)
                } else if !code.contains(#/[\-_]/#) {   // otherwise, only keep the “base” language
                    languages[code] = Language(endonym: endonym, exonym: exonym, id: code, localeId: code)
                }
            }
        }

        return languages.values.sorted(using: KeyPathComparator(\.id))
    }
    
    public var body: some View {
        ScrollViewReader { proxy in
            let filteredLanguages = query.isEmpty ? languages : languages.filter { $0.contains(query) }
            List(filteredLanguages) { lang in
                let endonym = Text(lang.endonym)
                let exonym: Text = {
                    if lang.exonymIsDifferent {
                        return Text("(\(lang.exonym))").foregroundColor(.secondary)
                    }
                    return Text("")
                }()
                Button(action: {
                    selectedLanguage = lang.id
                    onSelect(lang.id)
                }) {
                    HStack {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 0) { endonym; Text(" "); exonym }
                            VStack(alignment: .leading) { endonym; exonym }
                        }
                        if lang.id == selectedLanguage {
                        Spacer()
                          Image(systemName: "checkmark")
                                .foregroundStyle(Asset.Colors.Brand.blurple.swiftUIColor)
                        }
                    }
                }
                .tint(.primary)
                .accessibilityLabel(Text(lang.label))
                .id(lang.id)
            }
            .listStyle(.plain)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) { // when scrolling to quickly it'll overlap with other drawcycles and mess up the position :-(
                    if let selectedIndex = filteredLanguages.first(where: { $0.id == selectedLanguage }) {
                        proxy.scrollTo(selectedIndex.id, anchor: .center)
                    }
                }
            }
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        LanguagePicker(selectedLanguage: "en", onSelect: { _ in })
    }
}
