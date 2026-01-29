//
//  ShareViewModel.swift
//  MastodonShareAction
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import SwiftUI
import UniformTypeIdentifiers
import MastodonAsset
import MastodonLocalization
import MastodonUI
import MastodonCore

final class ShareViewModel {
    
    // input
    let context: AppContext
    @Published var authenticationBox: MastodonAuthenticationBox?
    
    @Published var isPublishing = false
    
    // output
    
    init(
        context: AppContext
    ) {
        self.context = context
        // end init
        
    }
    
}
