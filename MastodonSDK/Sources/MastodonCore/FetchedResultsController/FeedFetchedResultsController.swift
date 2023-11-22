//
//  FeedFetchedResultsController.swift
//  FeedFetchedResultsController
//
//  Created by Cirno MainasuK on 2021-8-19.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import UIKit
import Combine
import MastodonSDK

final public class FeedFetchedResultsController {

    @Published public var records: [MastodonFeed] = []

    public init() {}
}
