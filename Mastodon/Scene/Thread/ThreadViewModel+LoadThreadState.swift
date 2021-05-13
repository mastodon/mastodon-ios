//
//  ThreadViewModel+LoadThreadState.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import os.log
import Foundation
import Combine
import GameplayKit
import CoreDataStack
import MastodonSDK

extension ThreadViewModel {
    class LoadThreadState: GKState {
        weak var viewModel: ThreadViewModel?
                
        init(viewModel: ThreadViewModel) {
            self.viewModel = viewModel
        }
        
        override func didEnter(from previousState: GKState?) {
            os_log("%{public}s[%{public}ld], %{public}s: enter %s, previous: %s", ((#file as NSString).lastPathComponent), #line, #function, self.debugDescription, previousState.debugDescription)
        }
    }
}

extension ThreadViewModel.LoadThreadState {
    class Initial: ThreadViewModel.LoadThreadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:   return true
            default:                return false
            }
        }
    }
    
    class Loading: ThreadViewModel.LoadThreadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Fail.Type:      return true
            case is NoMore.Type:      return true
            default:                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            guard let mastodonAuthenticationBox = viewModel.context.authenticationService.activeMastodonAuthenticationBox.value else {
                stateMachine.enter(Fail.self)
                return
            }
            
            guard let rootNode = viewModel.rootNode.value else {
                stateMachine.enter(Fail.self)
                return
            }
            
            // trigger data source update
            viewModel.rootItem.value = viewModel.rootItem.value
            
            let domain = rootNode.domain
            let statusID = rootNode.statusID
            let replyToID = rootNode.replyToID
            
            viewModel.context.apiService.statusContext(
                domain: domain,
                statusID: statusID,
                mastodonAuthenticationBox: mastodonAuthenticationBox
            )
            .sink { completion in
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch status context for %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, statusID, error.localizedDescription)
                    stateMachine.enter(Fail.self)
                case .finished:
                    break
                }
            } receiveValue: { response in
                stateMachine.enter(NoMore.self)

                viewModel.ancestorNodes.value = ThreadViewModel.ReplyNode.replyToThread(
                    for: replyToID,
                    from: response.value.ancestors,
                    domain: domain,
                    managedObjectContext: viewModel.context.managedObjectContext
                )
                viewModel.descendantNodes.value = ThreadViewModel.LeafNode.tree(
                    for: rootNode.statusID,
                    from: response.value.descendants,
                    domain: domain,
                    managedObjectContext: viewModel.context.managedObjectContext
                )
            }
            .store(in: &viewModel.disposeBag)
        }

    }
    
    class Fail: ThreadViewModel.LoadThreadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            switch stateClass {
            case is Loading.Type:   return true
            default:                return false
            }
        }
        
        override func didEnter(from previousState: GKState?) {
            super.didEnter(from: previousState)
            
            guard let viewModel = viewModel, let stateMachine = stateMachine else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                stateMachine.enter(Loading.self)
            }
        }
    }
    
    class NoMore: ThreadViewModel.LoadThreadState {
        override func isValidNextState(_ stateClass: AnyClass) -> Bool {
            return false
        }
    }
    
}
