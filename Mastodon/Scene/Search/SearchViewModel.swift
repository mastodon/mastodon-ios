//
//  SearchViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Combine
import Foundation
import MastodonSDK
import OSLog
import UIKit

final class SearchViewModel {
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    
    // output
    let searchText = CurrentValueSubject<String, Never>("")
    
    var recommendHashTags = [Mastodon.Entity.Tag]()
    var recommendAccounts = [Mastodon.Entity.Account]()
    
    init(context: AppContext) {
        self.context = context
    }
    
    func requestRecommendHashTags() -> Future<Void, Error> {
        Future { promise in
            guard let activeMastodonAuthenticationBox = self.context.authenticationService.activeMastodonAuthenticationBox.value else {
                promise(.failure(APIService.APIError.implicit(APIService.APIError.ErrorReason.authenticationMissing)))
                return
            }
            self.context.apiService.recommendTrends(domain: activeMastodonAuthenticationBox.domain, query: nil)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendHashTags request fail: %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                        promise(.failure(error))
                    case .finished:
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendHashTags request success", (#file as NSString).lastPathComponent, #line, #function)
                        promise(.success(()))
                    }
                } receiveValue: { [weak self] tags in
                    guard let self = self else { return }
                    self.recommendHashTags = tags.value
                }
                .store(in: &self.disposeBag)
        }
    }

    func requestRecommendAccounts() -> Future<Void, Error> {
        Future { promise in
            guard let activeMastodonAuthenticationBox = self.context.authenticationService.activeMastodonAuthenticationBox.value else {
                promise(.failure(APIService.APIError.implicit(APIService.APIError.ErrorReason.authenticationMissing)))
                return
            }
            self.context.apiService.recommendAccount(domain: activeMastodonAuthenticationBox.domain, query: nil, mastodonAuthenticationBox: activeMastodonAuthenticationBox)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendHashTags request fail: %s", (#file as NSString).lastPathComponent, #line, #function, error.localizedDescription)
                        promise(.failure(error))
                    case .finished:
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendHashTags request success", (#file as NSString).lastPathComponent, #line, #function)
                        promise(.success(()))
                    }
                } receiveValue: { [weak self] accounts in
                    guard let self = self else { return }
                    self.recommendAccounts = accounts.value
                }
                .store(in: &self.disposeBag)
        }
    }
}
