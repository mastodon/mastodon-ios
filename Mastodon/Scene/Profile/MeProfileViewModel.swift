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
        super.init(
            context: context,
            authContext: authContext,
            optionalMastodonUser: authContext.mastodonAuthenticationBox.inMemoryCache.meAccount
        )
        
        $me
            .sink { [weak self] me in
                guard let self = self else { return }
                self.user = me
            }
            .store(in: &disposeBag)
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        Task {
            do {
                self.me = try await context.apiService.authenticatedUserInfo(authenticationBox: authContext.mastodonAuthenticationBox).value
            } catch {
                // do nothing?
            }
        }
    }
}
