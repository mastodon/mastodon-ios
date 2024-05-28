// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation

class PrivacySafetyViewModel: ObservableObject {
    enum Preset {
        case openPublic, privateRestricted, custom
    }
    
    @Published var preset: Preset = .openPublic
}
