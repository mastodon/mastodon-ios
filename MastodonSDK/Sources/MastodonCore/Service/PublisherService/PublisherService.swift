//
//  PublisherService.swift
//  
//
//  Created by MainasuK on 2021-12-2.
//

import os.log
import UIKit
import Combine

public final class PublisherService {
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "PublisherService", category: "Service")
    
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
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): publish progress \(progress.fractionCompleted)")
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
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): publish status…")
                let result = try await publisher.publish(api: apiService, authContext: authContext)
                
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): publish status success")
                self.statusPublishResult.send(.success(result))
                self.statusPublishers.removeAll(where: { $0 === publisher })
                
            } catch is CancellationError {
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): publish cancelled")
                self.statusPublishers.removeAll(where: { $0 === publisher })
                
            } catch {
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): publish failure: \(error.localizedDescription)")
                self.statusPublishResult.send(.failure(error))
                self.currentPublishProgress = 0
            }
        }
    }
}
