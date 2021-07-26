//
//  APIService.swift
//  MastodonIntent
//
//  Created by Cirno MainasuK on 2021-7-26.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

// Replica APIService for share extension
final class APIService {

    var disposeBag = Set<AnyCancellable>()

    static let shared = APIService()

    // internal
    let session: URLSession

    // output
    let error = PassthroughSubject<APIError, Never>()

    private init() {
        self.session = URLSession(configuration: .default)
    }

}

