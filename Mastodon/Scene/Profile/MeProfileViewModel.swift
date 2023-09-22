//
//  MeProfileViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonCore
import MastodonSDK

final class MeProfileViewModel: ProfileViewModel {
    
    init(context: AppContext, authContext: AuthContext) {
        let user = authContext.mastodonAuthenticationBox.authenticationRecord.object(in: context.managedObjectContext)?.user
        super.init(
            context: context,
            authContext: authContext,
            optionalMastodonUser: user
        )
        
        $me
            .sink { [weak self] me in
                guard let self = self else { return }
                self.user = me
            }
            .store(in: &disposeBag)
    }
    
}
