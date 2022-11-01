//
//  CachedProfileViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-31.
//

import Foundation
import CoreDataStack
import MastodonCore

final class CachedProfileViewModel: ProfileViewModel {
    
    init(context: AppContext, authContext: AuthContext, mastodonUser: MastodonUser) {
        super.init(context: context, authContext: authContext, optionalMastodonUser: mastodonUser)
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Profile] user[\(mastodonUser.id)] profile: \(mastodonUser.acctWithDomain)")
    }
    
}
