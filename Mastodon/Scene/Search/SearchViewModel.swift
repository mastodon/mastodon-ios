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

final class SearchViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    

    let context: AppContext
    // input
    let username = CurrentValueSubject<String, Never>("")
    
    init(context: AppContext) {
        self.context  = context
    }
}
