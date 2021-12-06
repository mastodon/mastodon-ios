//
//  WelcomeViewModel.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-15.
//

import Foundation
import Combine

final class WelcomeViewModel {
 
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    
    // output
    let needsShowDismissEntry = CurrentValueSubject<Bool, Never>(false)
    
    init(context: AppContext) {
        self.context = context
        
        context.authenticationService.mastodonAuthentications
            .map { !$0.isEmpty }
            .assign(to: \.value, on: needsShowDismissEntry)
            .store(in: &disposeBag)
    }
    
}
