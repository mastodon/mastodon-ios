//
//  MastodonConfirmEmailViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/23.
//

import Combine
import Foundation
import MastodonSDK
import os.log

final class MastodonConfirmEmailViewModel {
    var disposeBag = Set<AnyCancellable>()

    let context: AppContext
    let coordinator: SceneCoordinator
    var email: String
    let authenticateInfo: AuthenticationViewModel.AuthenticateInfo
    let userToken: Mastodon.Entity.Token

    let timestampUpdatePublisher = Timer.publish(every: 4.0, on: .main, in: .common)
        .autoconnect()
        .share()
        .eraseToAnyPublisher()

    init(context: AppContext,coordinator: SceneCoordinator, email: String, authenticateInfo: AuthenticationViewModel.AuthenticateInfo, userToken: Mastodon.Entity.Token) {
        self.context = context
        self.coordinator = coordinator
        self.email = email
        self.authenticateInfo = authenticateInfo
        self.userToken = userToken
        timestampUpdatePublisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                AuthenticationViewModel.verifyAndSaveAuthentication(context: self.context, info: authenticateInfo, userToken: userToken)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        switch completion {
                        case .failure(let error):
                            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: swap user access token swap fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                        case .finished:
                            break
                        }
                    } receiveValue: { _ in
                        self.coordinator.setup()
                    }
                    .store(in: &self.disposeBag)

            }
            .store(in: &disposeBag)
    }
}
