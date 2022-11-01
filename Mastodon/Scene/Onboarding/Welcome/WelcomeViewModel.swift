//
//  WelcomeViewModel.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-15.
//

import Foundation
import Combine
import MastodonCore

final class WelcomeViewModel {
 
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    
    // output
    @Published var needsShowDismissEntry = false
    
    init(context: AppContext) {
        self.context = context
        
        context.authenticationService.$mastodonAuthenticationBoxes
            .map { !$0.isEmpty }
            .assign(to: &$needsShowDismissEntry)
    }
    
}
