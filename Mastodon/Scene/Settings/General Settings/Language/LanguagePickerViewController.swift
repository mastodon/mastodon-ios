// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import MastodonLocalization
import MastodonUI
import SwiftUI

class LanguagePickerViewController: UIHostingController<LanguagePicker> {
    private let onLanguageSelected: OnLanguageSelected

    init(onLanguageSelected: @escaping OnLanguageSelected) {
        self.onLanguageSelected = onLanguageSelected
        super.init(rootView: LanguagePicker(selectedLanguage: UserDefaults.shared.defaultPostLanguage, onSelect:self.onLanguageSelected))
        title = L10n.Scene.Settings.General.Language.defaultPostLanguage
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
