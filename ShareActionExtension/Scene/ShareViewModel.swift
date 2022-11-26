//
//  ShareViewModel.swift
//  MastodonShareAction
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import os.log
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
    
    let logger = Logger(subsystem: "ComposeViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let context: AppContext
    @Published var authContext: AuthContext?
    
    @Published var isPublishing = false
    
    // output
    
    init(
        context: AppContext
    ) {
        self.context = context
        // end init
        
    }
    
}
