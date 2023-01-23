// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import MastodonLocalization
import SwiftUI

struct LanguagePicker: View {
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private struct Language: Identifiable {
        let endonym: String
        let exonym: String
        let id: String
        let localeId: String
        
        func contains(_ query: String) -> Bool {
            "\(endonym) \(exonym) \(id)".localizedCaseInsensitiveContains(query)
        }
    }
    
    @State private var query = ""
    @State private var languages: [Language] = {
        let locales = Locale.availableIdentifiers.map(Locale.init(identifier:))
        var languages: [String: Language] = [:]
        for locale in locales {
            if let code = locale.languageCode,
               let endonym = locale.localizedString(forLanguageCode: code),
               let exonym = Locale.current.localizedString(forLanguageCode: code) {
                // don’t overwrite the “base” language
                if let lang = languages[code], !lang.localeId.contains("_") { continue }
                languages[code] = Language(endonym: endonym, exonym: exonym, id: code, localeId: locale.identifier)
            }
        }
        return languages.values.sorted(using: KeyPathComparator(\.id))
    }()

    var body: some View {
        NavigationView {
            let filteredLanguages = query.isEmpty ? languages : languages.filter { $0.contains(query) }
            List(filteredLanguages) { lang in
                let endonym = Text(lang.endonym).
                let exonym: Text = {
                    if lang.endonym.caseInsensitiveCompare(lang.exonym) == .orderedSame {
                        return Text("")
                    }
                    return Text("(\(lang.exonym))").foregroundColor(.secondary)
                }()
                Button(action: { onSelect(lang.id) }) {
                    if #available(iOS 16.0, *) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 0) { endonym; Text(" "); exonym }
                            VStack(alignment: .leading) { endonym; exonym }
                        }
                    } else {
                        // less optimal because if you’re using an LTR language, RTL languages
                        // will read as “ ([exonym])[endonym]” (and vice versa in RTL locales)
                        Text("\(endonym)\(exonym)")
                    }
                }.tint(.primary)
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
