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
    
    @MainActor
    init(context: AppContext, authContext: AuthContext) {
        let user = authContext.mastodonAuthenticationBox.authentication.user(in: context.managedObjectContext)
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

    override func viewDidLoad() {

        super.viewDidLoad()

        Task {
            do {

                _ = try await context.apiService.authenticatedUserInfo(authenticationBox: authContext.mastodonAuthenticationBox).value

                try await context.managedObjectContext.performChanges {
                    guard let me = self.authContext.mastodonAuthenticationBox.authentication.user(in: self.context.managedObjectContext) else {
                        assertionFailure()
                        return
                    }

                    self.me = me
                }
            } catch {
                // do nothing?
            }
        }
    }
}
