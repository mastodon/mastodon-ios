//
//  CachedProfileViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-31.
//

import Foundation
import CoreDataStack

final class CachedProfileViewModel: ProfileViewModel {
    
    convenience init(context: AppContext, mastodonUser: MastodonUser) {
        self.init(context: context, optionalMastodonUser: mastodonUser)
    }
    
}
