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
        let me = authContext.mastodonAuthenticationBox.authentication.account()
        super.init(
            context: context,
            authContext: authContext,
            account: me
        )
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        Task {
            do {
                let account = try await context.apiService.authenticatedUserInfo(authenticationBox: authContext.mastodonAuthenticationBox).value
                self.account = account
                self.me = account
            } catch {
                // do nothing?
            }
        }
    }
}
