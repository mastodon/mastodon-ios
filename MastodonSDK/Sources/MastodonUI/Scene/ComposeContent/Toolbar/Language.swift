// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

// Consider replacing this with Locale.Language when dropping iOS 15
struct Language: Identifiable {
    let endonym: String
    let exonym: String
    let id: String
    let localeId: String?
    
    init(endonym: String, exonym: String, id: String, localeId: String?) {
        self.endonym = endonym
        self.exonym = exonym
        self.id = id
        self.localeId = localeId
    }
    
    init?(id: String) {
        guard let endonym = Locale(identifier: id).localizedString(forLanguageCode: id),
              let exonym = Locale.current.localizedString(forLanguageCode: id)
        else { return nil }
        self.endonym = endonym
        self.exonym = exonym
        self.id = id
        self.localeId = nil
    }
    
    func contains(_ query: String) -> Bool {
        "\(endonym) \(exonym) \(id)".localizedCaseInsensitiveContains(query)
    }
    
    var exonymIsDifferent: Bool {
        endonym.caseInsensitiveCompare(exonym) != .orderedSame
    }
    
    var label: AttributedString {
        AttributedString(endonym, attributes: AttributeContainer([.languageIdentifier: id]))
        + AttributedString(exonymIsDifferent ? " (\(exonym))" : "")
    }
}
