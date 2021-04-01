//
//  SearchViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Foundation
import Combine
import MastodonSDK
import UIKit
import OSLog

final class SearchViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    
    // output
    let searchText = CurrentValueSubject<String, Never>("")
    
    var recommendHashTags = [Mastodon.Entity.Tag]()
    var recommendAccounts = [Mastodon.Entity.Account]()
    
    init(context: AppContext) {
        self.context  = context
    }
    
    func requestRecommendData() {
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        let trendsAPI = context.apiService.recommendTrends(domain: activeMastodonAuthenticationBox.domain, query: Mastodon.API.Trends.Query(limit: 5))
//            .sink { completion in
//                switch completion {
//                case .failure(let error):
//                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendTrends fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                case .finished:
//                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendTrends success", ((#file as NSString).lastPathComponent), #line, #function)
//                    break
//                }
//
//            } receiveValue: { [weak self] tags in
//                guard let self = self else { return }
//                self.recommendHashTags = tags.value
//            }
//            .store(in: &disposeBag)
       
        let accountsAPI = context.apiService.recommendAccount(domain: activeMastodonAuthenticationBox.domain, query: nil, mastodonAuthenticationBox: activeMastodonAuthenticationBox)
//            .sink { completion in
//                switch completion {
//                case .failure(let error):
//                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendAccount fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
//                case .finished:
//                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: recommendAccount success", ((#file as NSString).lastPathComponent), #line, #function)
//                    break
//                }
//            } receiveValue: { [weak self] accounts in
//                guard let self = self else { return }
//                self.recommendAccounts = accounts.value
//            }
//            .store(in: &disposeBag)
        Publishers.Zip(trendsAPI,accountsAPI)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: zip request fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                case .finished:
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: zip request success", ((#file as NSString).lastPathComponent), #line, #function)
                    break
                }
            } receiveValue: { [weak self] (tags, accounts) in
                guard let self = self else { return }
                self.recommendAccounts = accounts.value
                self.recommendHashTags = tags.value
            }
            .store(in: &disposeBag)
    }
}
