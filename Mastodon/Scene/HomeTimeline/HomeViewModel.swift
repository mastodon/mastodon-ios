//
//  HomeViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-4.
//

import UIKit
import Combine

final class HomeViewModel {
    
    // input
    let context: AppContext
    let viewDidAppear = PassthroughSubject<Void, Never>()

    // output
    
    init(context: AppContext) {
        self.context = context
    }
    
}

