//
//  CachedThreadViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import Foundation
import CoreDataStack

final class CachedThreadViewModel: ThreadViewModel {
    init(context: AppContext, status: Status) {
        super.init(context: context, optionalStatus: status)
    }
}
