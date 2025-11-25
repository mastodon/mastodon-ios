// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK
import MastodonCore

/// AsyncRefreshViewModel
/// For use with the AsyncRefresh API, this view model manages polling for async updates at the server-requested rate and reporting them in a way that is easy for SwfitUI views to consume.
/// You can create an AsyncRefreshViewModel for any view, whether you expect to receive an AsyncRefresh header or not, because it will remain in the default .noAsyncRefresh state (reporting refreshButtonState of .hidden) until you call beginPollingForResults(asyncRefresh: authenticationBox:).  You can call beginPollingForResults(asyncRefresh: authenticationBox:) multiple times. Calls with the same asyncRefresh id will be ignored, a call with a new one will reset the model to poll the new id.
/// Before manually refreshing from the original endpoint that returned the AsyncRefreshAvailable, always call willRefreshFromOriginalEndpoint() and do not do the refresh if this returns false (it will always return true if beginPollingForResults has not been called). This will prevent exceeding the server-requested rate.
/// You must then call didRefreshFromOriginalEndpoint() to resume polling for new results and update the button state.

@Observable public class AsyncRefreshViewModel {
    
    public enum RefreshButtonState {
        case hidden
        case newResultsExpected
        case fetching
    }
    public private(set) var refreshButtonState: RefreshButtonState = .hidden
    private var publishTimer: Timer?
    private var publishInterval: TimeInterval?
    
    private enum AsyncRefreshState {
        case noAsyncRefresh
        case running(resultCount: Int?)
        case finished(resultCount: Int?)
        case error(Error)
        
        var expectedResultCount: Int? {
            switch self {
            case .noAsyncRefresh:
                return nil
            case .running(let resultCount), .finished(let resultCount):
                return resultCount
            case .error(_):
                return nil
            }
        }
    }
    private var state: AsyncRefreshState = .noAsyncRefresh
    private var pollingTimer: Timer?
    private var pollingInterval: TimeInterval?
    
    private var asyncRefreshId: String?
    private var authBox: MastodonAuthenticationBox?
    
    private struct ManualRefresh {
        let timestamp: Date
        let expectedResultCount: Int?
    }
    private var lastManualRefresh: ManualRefresh?
    
    public func beginPollingForResults(_ asyncRefresh: Mastodon.Response.AsyncRefreshAvailable, withSecondsBetweenButtonUpdate publishInterval: Double, authenticationBox: MastodonAuthenticationBox) {
        guard asyncRefreshId != asyncRefresh.id else { return }
        if asyncRefreshId != nil {
            resetForNewAsyncRefresh()
        }
        
        authBox = authenticationBox
        pollingInterval = TimeInterval(asyncRefresh.retryInterval)
        self.publishInterval = TimeInterval(publishInterval)
        asyncRefreshId = asyncRefresh.id
        state = .running(resultCount: asyncRefresh.resultCount)
        lastManualRefresh = ManualRefresh(timestamp: .now, expectedResultCount: asyncRefresh.resultCount)
        resetPollingTimer()
        resetPublishingTimer()
    }
    
    private func resetForNewAsyncRefresh() {
        state = .noAsyncRefresh
        asyncRefreshId = nil
        pollingInterval = nil
        publishInterval = nil
        lastManualRefresh = nil
        pollingTimer?.invalidate()
        pollingTimer = nil
        publishTimer?.invalidate()
        publishTimer = nil
        refreshButtonState = .hidden
    }
    
    private var isOkToRefresh: Bool {
        switch state {
        case .noAsyncRefresh:
            return true
        case .running, .finished:
            guard let lastManualRefresh, let pollingInterval else { return true }
            return Date.now.timeIntervalSince(lastManualRefresh.timestamp) > pollingInterval
        case .error:
            return false
        }
    }
    
    public func willRefreshFromOriginalEndpoint() -> Bool {
        guard isOkToRefresh else { return false }
        
        pollingTimer?.invalidate()
        publishTimer?.invalidate()
        lastManualRefresh = ManualRefresh(timestamp: .now, expectedResultCount: state.expectedResultCount)
        switch refreshButtonState {
        case .hidden, .fetching:
            break
        case .newResultsExpected:
            refreshButtonState = .fetching
        }
        return true
    }
    
    public func didRefreshFromOriginalEndpoint() {
        resetPollingTimer()
        resetPublishingTimer()
        updateButtonState()
    }
    
    private func updateButtonState() {
        switch state {
        case .noAsyncRefresh:
            refreshButtonState = .hidden
            
        case .running(let resultCount):
            guard let lastManualRefresh, let publishInterval else { return }
            let newResultsExpected = (resultCount ?? 0) > (lastManualRefresh.expectedResultCount ?? 0)
            let sufficientTimeElapsed = Date.now.timeIntervalSince(lastManualRefresh.timestamp) > publishInterval
            refreshButtonState = newResultsExpected && sufficientTimeElapsed ? .newResultsExpected : .hidden

        case .finished(let resultCount):
            let newResultsExpected = (resultCount ?? 0) > (lastManualRefresh?.expectedResultCount ?? 0)
            refreshButtonState = newResultsExpected ? .newResultsExpected : .hidden

        case .error:
            refreshButtonState = .hidden
        }
    }
    
    private func resetPublishingTimer() {
        publishTimer?.invalidate()
        guard let publishInterval else { return }
        
        switch state {
        case .noAsyncRefresh, .finished, .error:
            return
        case .running:
            publishTimer = Timer.scheduledTimer(withTimeInterval: publishInterval, repeats: false) { [weak self] _ in
                self?.updateButtonState()
                self?.resetPublishingTimer()
            }
        }
    }
    
    private func resetPollingTimer() {
        
        pollingTimer?.invalidate()
        guard let pollingInterval else { return }
        
        switch state {
        case .noAsyncRefresh, .finished, .error:
            return
        case .running:
            pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: false) { _ in
                Task { [weak self] in
                    guard let asyncRefreshId = self?.asyncRefreshId, let authBox = self?.authBox else {
                        return
                    }
                    guard self?.isOkToRefresh == true else {
                        assertionFailure("retried too soon")
                        self?.resetPollingTimer()
                        return
                    }
                    do {
                        let result = try await APIService.shared.fetchAsyncRefreshUpdate(forAsyncRefreshID: asyncRefreshId, authenticationBox: authBox)
                        switch result.status {
                        case .running:
                            self?.state = .running(resultCount: result.resultCount)
                        case .finished:
                            self?.state = .finished(resultCount: result.resultCount)
                            self?.updateButtonState()
                        case ._other(let otherValue):
                            assertionFailure("unexpected AsyncRefresh state value \(otherValue); will stop")
                            self?.state = .finished(resultCount: result.resultCount)
                            self?.updateButtonState()
                        }
                    } catch {
#if DEBUG
                        print("Error fetching async refresh update: \(error)")
#endif
                        self?.state = .error(error)
                        self?.updateButtonState()
                    }
                    self?.resetPollingTimer()
                }
            }
        }
    }
}
