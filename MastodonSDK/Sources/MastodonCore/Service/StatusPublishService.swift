//
//  StatusPublishService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-26.
//

import Foundation
import Intents
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import UIKit

public final class StatusPublishService {
    
    var disposeBag = Set<AnyCancellable>()
    
    let workingQueue = DispatchQueue(label: "org.joinmastodon.app.StatusPublishService.working-queue")

    // input
    // var viewModels = CurrentValueSubject<[ComposeViewModel], Never>([])     // use strong reference to retain the view models
    
    // output
    let composeViewModelDidUpdatePublisher = PassthroughSubject<Void, Never>()
    // let latestPublishingComposeViewModel = CurrentValueSubject<ComposeViewModel?, Never>(nil)
}
