//
//  PublisherService.swift
//  
//
//  Created by MainasuK on 2021-12-2.
//

import UIKit
import Combine

public final class PublisherService {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let apiService: APIService

    @Published public private(set) var statusPublishers: [StatusPublisher] = []
    
    // output
    public let statusPublishResult = PassthroughSubject<Result<StatusPublishResult, Error>, Never>()

    var currentPublishProgressObservation: NSKeyValueObservation?
    @Published public var currentPublishProgress: Double = 0
    
    public init(
        apiService: APIService
    ) {
        self.apiService = apiService
        
        $statusPublishers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] publishers in
                guard let self = self else { return }
                guard let last = publishers.last else {
                    self.currentPublishProgressObservation = nil
                    return
                }
                
                self.currentPublishProgressObservation = last.progress
                    .observe(\.fractionCompleted, options: [.initial, .new]) { [weak self] progress, _ in
                        guard let self = self else { return }
                        self.currentPublishProgress = progress.fractionCompleted
                    }
            }
            .store(in: &disposeBag)
        
        $statusPublishers
            .filter { $0.isEmpty }
            .delay(for: 1, scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.currentPublishProgress = 0
            }
            .store(in: &disposeBag)
        
        statusPublishResult
            .receive(on: DispatchQueue.main)
            .sink { result in
                switch result {
                case .success:
                    break
                    // TODO:
                    // update store review count trigger
                    // UserDefaults.shared.storeReviewInteractTriggerCount += 1
                case .failure:
                    break
                }
            }
            .store(in: &disposeBag)
    }
    
}

extension PublisherService {
    
    @MainActor
    public func enqueue(statusPublisher publisher: StatusPublisher, authContext: AuthContext) {
        guard !statusPublishers.contains(where: { $0 === publisher }) else {
            assertionFailure()
            return
        }
        statusPublishers.append(publisher)
        
        Task {
            do {
                let result = try await publisher.publish(api: apiService, authContext: authContext)
                
                self.statusPublishResult.send(.success(result))
                self.statusPublishers.removeAll(where: { $0 === publisher })
                
            } catch is CancellationError {
                self.statusPublishers.removeAll(where: { $0 === publisher })
                
            } catch {
                self.statusPublishResult.send(.failure(error))
                self.currentPublishProgress = 0
            }
        }
    }
}
