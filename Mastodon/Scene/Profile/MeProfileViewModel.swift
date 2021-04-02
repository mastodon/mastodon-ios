//
//  MeProfileViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

final class MeProfileViewModel: ProfileViewModel {
    
    init(context: AppContext) {
        super.init(
            context: context,
            optionalMastodonUser: context.authenticationService.activeMastodonAuthentication.value?.user
        )
        
        self.currentMastodonUser
            .sink { [weak self] currentMastodonUser in
                os_log("%{public}s[%{public}ld], %{public}s: current active twitter user: %s", ((#file as NSString).lastPathComponent), #line, #function, currentMastodonUser?.username ?? "<nil>")
                
                guard let self = self else { return }
                self.mastodonUser.value = currentMastodonUser
            }
            .store(in: &disposeBag)
    }
    
}
