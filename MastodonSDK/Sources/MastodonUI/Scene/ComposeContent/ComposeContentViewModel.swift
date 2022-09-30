//
//  ComposeContentViewModel.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import Foundation
import MastodonCore

final class ComposeContentViewModel: ObservableObject {
    
    // input
    let context: AppContext
    
    init(context: AppContext) {
        self.context = context
    }
    
}
