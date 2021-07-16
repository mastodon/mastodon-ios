//
//  ShareViewModel.swift
//  MastodonShareAction
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack

final class ShareViewModel {

    let logger = Logger(subsystem: "ShareViewModel", category: "logic")

    var disposeBag = Set<AnyCancellable>()

    // input
    let viewDidAppear = CurrentValueSubject<Bool, Never>(false)
    private var coreDataStack: CoreDataStack?
    var managedObjectContext: NSManagedObjectContext?

    // output
    let authentication = CurrentValueSubject<Result<MastodonAuthentication, Error>?, Never>(nil)
    let isFetchAuthentication = CurrentValueSubject<Bool, Never>(true)
    let isBusy = CurrentValueSubject<Bool, Never>(true)
    let isValid = CurrentValueSubject<Bool, Never>(false)

    init() {
        viewDidAppear.receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] viewDidAppear in
                guard let self = self else { return }
                guard viewDidAppear else { return }
                self.setupCoreData()
            }
            .store(in: &disposeBag)

        authentication
            .map { result in result == nil }
            .assign(to: \.value, on: isFetchAuthentication)
            .store(in: &disposeBag)

        isFetchAuthentication
            .receive(on: DispatchQueue.main)
            .assign(to: \.value, on: isBusy)
            .store(in: &disposeBag)
    }

}

extension ShareViewModel {
    enum ShareError: Error {
        case `internal`(error: Error)
        case userCancelShare
        case missingAuthentication
    }
}

extension ShareViewModel {
    private func setupCoreData() {
        logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        DispatchQueue.global().async {
            let _coreDataStack = CoreDataStack()
            self.coreDataStack = _coreDataStack
            self.managedObjectContext = _coreDataStack.persistentContainer.viewContext

            _coreDataStack.didFinishLoad
                .receive(on: RunLoop.main)
                .sink { [weak self] didFinishLoad in
                    guard let self = self else { return }
                    guard didFinishLoad else { return }
                    guard let managedObjectContext = self.managedObjectContext else { return }

                    self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch authentication…")
                    managedObjectContext.perform {
                        do {
                            let request = MastodonAuthentication.sortedFetchRequest
                            let authentications = try managedObjectContext.fetch(request)
                            let authentication = authentications.sorted(by: { $0.activedAt > $1.activedAt }).first
                            guard let activeAuthentication = authentication else {
                                self.authentication.value = .failure(ShareError.missingAuthentication)
                                return
                            }
                            self.authentication.value = .success(activeAuthentication)
                            self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch authentication success \(activeAuthentication.userID)")
                        } catch {
                            self.authentication.value = .failure(ShareError.internal(error: error))
                            self.logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fetch authentication fail \(error.localizedDescription)")
                            assertionFailure(error.localizedDescription)
                        }
                    }
                }
                .store(in: &self.disposeBag)
        }
    }
}
