//
//  MastodonConfirmEmailViewModel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/23.
//

import Combine

final class MastodonConfirmEmailViewModel {
    var disposeBag = Set<AnyCancellable>()
    
    let context: AppContext
    var email: String
    
    init(context: AppContext, email: String) {
        self.context = context
        self.email = email
    }
}

