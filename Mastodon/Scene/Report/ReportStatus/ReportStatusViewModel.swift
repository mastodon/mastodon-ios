//
//  ReportStatusViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-10.
//

import Combine
import Foundation
import GameplayKit
import MastodonSDK
import OrderedCollections
import UIKit
import MastodonCore
import SwiftUI

class ReportStatusViewModel {
    
    var disposeBag = Set<AnyCancellable>()

    weak var delegate: ReportStatusViewControllerDelegate?
    
    // input
    let context: AppContext
    let authenticationBox: MastodonAuthenticationBox
    let account: Mastodon.Entity.Account
    let status: MastodonStatus?
    let dataController: StatusDataController

    @Published var isSkip = false
    @Published var selectStatuses = OrderedSet<MastodonStatus>()
    
    private var postViewModels = [Mastodon.Entity.Status.ID : MastodonPostViewModel]()
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ReportSection, ReportItem>?
    private(set) lazy var stateMachine: GKStateMachine = {
        let stateMachine = GKStateMachine(states: [
            State.Initial(viewModel: self),
            State.Fail(viewModel: self),
            State.Idle(viewModel: self),
            State.Loading(viewModel: self),
            State.NoMore(viewModel: self),
        ])
        stateMachine.enter(State.Initial.self)
        return stateMachine
    }()
    
    @Published var isNextButtonEnabled = false
    
    @MainActor
    init(
        context: AppContext,
        authenticationBox: MastodonAuthenticationBox,
        account: Mastodon.Entity.Account,
        status: MastodonStatus?
    ) {
        self.context = context
        self.authenticationBox = authenticationBox
        self.account = account
        self.status = status
        self.dataController = StatusDataController()
        // end init
        
        if let status = status {
            selectStatuses.append(status)
        }

        $selectStatuses
            .map { !$0.isEmpty }
            .assign(to: &$isNextButtonEnabled)
    }

}

extension ReportStatusViewModel {
    @MainActor
    func postViewModel(_ selectableStatus: MastodonStatus) -> MastodonPostViewModel? {
        if let existing = postViewModels[selectableStatus.id] {
            return existing
        } else {
            let post = GenericMastodonPost.fromStatus(selectableStatus.entity, authenticatedDomain: authenticationBox.domain)
            let newModel = MastodonPostViewModel(post.initialDisplayInfo(), displayType: .standard)
            newModel.initialSetFullPost(post)
            postViewModels[selectableStatus.id] = newModel
            return newModel
        }
    }
    
    @MainActor
    func canDeselect(_ selectableStatus: MastodonStatus) -> Bool {
        guard selectableStatus.id != status?.id else { return false }
        return true
    }
    
    @MainActor
    func isSelected(_ selectableStatus: MastodonStatus) -> Binding<Bool> {
        Binding<Bool>(
            get: { [weak self] in
                guard let self else { return false }
                return selectableStatus.id == self.status?.id || self.selectStatuses.contains(where: { selectableStatus.id == $0.id } )
            },
            set: { [weak self] newValue in
                guard let self else { return }
                guard newValue || canDeselect(selectableStatus) else { return }
                if newValue {
                    selectStatuses.append(selectableStatus)
                } else {
                    selectStatuses.remove(selectableStatus)
                }
            }
        )
    }
}
