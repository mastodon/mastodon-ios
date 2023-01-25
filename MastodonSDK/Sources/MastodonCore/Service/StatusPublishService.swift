//
//  StatusPublishService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-26.
//

import os.log
import Foundation
import Intents
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import UIKit

public final class StatusPublishService {
    
    var disposeBag = Set<AnyCancellable>()
    
    let workingQueue = DispatchQueue(label: "com.emerge.mastodon.StatusPublishService.working-queue")

    // input
    // var viewModels = CurrentValueSubject<[ComposeViewModel], Never>([])     // use strong reference to retain the view models
    
    // output
    let composeViewModelDidUpdatePublisher = PassthroughSubject<Void, Never>()
    // let latestPublishingComposeViewModel = CurrentValueSubject<ComposeViewModel?, Never>(nil)
    
    init() {
//        Publishers.CombineLatest(
//            viewModels.eraseToAnyPublisher(),
//            composeViewModelDidUpdatePublisher.eraseToAnyPublisher()
//        )
//        .map { viewModels, _ in viewModels.last }
//        .assign(to: \.value, on: latestPublishingComposeViewModel)
//        .store(in: &disposeBag)
    }
    
}

extension StatusPublishService {

//    func publish(composeViewModel: ComposeViewModel) {
//        workingQueue.sync {
//            guard !self.viewModels.value.contains(where: { $0 === composeViewModel }) else { return }
//            self.viewModels.value = self.viewModels.value + [composeViewModel]
//            
//            composeViewModel.publishStateMachinePublisher
//                .receive(on: DispatchQueue.main)
//                .sink { [weak self, weak composeViewModel] state in
//                    guard let self = self else { return }
//                    guard let composeViewModel = composeViewModel else { return }
//                    
//                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: composeViewModelDidUpdate", ((#file as NSString).lastPathComponent), #line, #function)
//                    self.composeViewModelDidUpdatePublisher.send()
//
//                    switch state {
//                    case is ComposeViewModel.PublishState.Finish:
//                        self.remove(composeViewModel: composeViewModel)
//                    default:
//                        break
//                    }
//                }
//                .store(in: &composeViewModel.disposeBag)    // cancel subscription when viewModel dealloc
//        }
//    }
//    
//    func remove(composeViewModel: ComposeViewModel) {
//        workingQueue.async {
//            var viewModels = self.viewModels.value
//            viewModels.removeAll(where: { $0 === composeViewModel })
//            self.viewModels.value = viewModels
//            
//            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: composeViewModel removed", ((#file as NSString).lastPathComponent), #line, #function)
//        }
//    }
    
}
