// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import MastodonLocalization
import SwiftUI

struct LanguagePicker: View {
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var query = ""
    @State private var languages: [Language] = {
        let locales = Locale.availableIdentifiers.map(Locale.init(identifier:))
        var languages: [String: Language] = [:]
        for locale in locales {
            if let code = locale.language.languageCode?.identifier,
               let endonym = locale.localizedString(forLanguageCode: code),
               let exonym = Locale.current.localizedString(forLanguageCode: code) {
                // don’t overwrite the “base” language
                if let lang = languages[code], !(lang.localeId ?? "").contains("_") { continue }
                languages[code] = Language(endonym: endonym, exonym: exonym, id: code, localeId: locale.identifier)
            }
        }
        return languages.values.sorted(using: KeyPathComparator(\.id))
    }()

    var body: some View {
        NavigationView {
            let filteredLanguages = query.isEmpty ? languages : languages.filter { $0.contains(query) }
            List(filteredLanguages) { lang in
                let endonym = Text(lang.endonym)
                let exonym: Text = {
                    if lang.exonymIsDifferent {
                        return Text("(\(lang.exonym))").foregroundColor(.secondary)
                    }
                    return Text("")
                }()
                Button(action: { onSelect(lang.id) }) {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 0) { endonym; Text(" "); exonym }
                        VStack(alignment: .leading) { endonym; exonym }
                    }
                }
                .tint(.primary)
                .accessibilityLabel(Text(lang.label))
            }.toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.Controls.Actions.cancel) {
                        dismiss()
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle(L10n.Scene.Compose.Language.title)
            .navigationBarTitleDisplayMode(.inline)
        }.navigationViewStyle(.stack)
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        LanguagePicker(onSelect: { _ in })
    }
}
