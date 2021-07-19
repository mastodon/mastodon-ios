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
import MastodonUI
import SwiftUI
import UniformTypeIdentifiers

final class ShareViewModel {

    let logger = Logger(subsystem: "ShareViewModel", category: "logic")

    var disposeBag = Set<AnyCancellable>()

    static let composeContentLimit: Int = 500

    // input
    private var coreDataStack: CoreDataStack?
    var managedObjectContext: NSManagedObjectContext?
    var inputItems = CurrentValueSubject<[NSExtensionItem], Never>([])
    let viewDidAppear = CurrentValueSubject<Bool, Never>(false)
    let traitCollectionDidChangePublisher = CurrentValueSubject<Void, Never>(Void())      // use CurrentValueSubject to make initial event emit
    let selectedStatusVisibility = CurrentValueSubject<ComposeToolbarView.VisibilitySelectionType, Never>(.public)

    // output
    let authentication = CurrentValueSubject<Result<MastodonAuthentication, Error>?, Never>(nil)
    let isFetchAuthentication = CurrentValueSubject<Bool, Never>(true)
    let isBusy = CurrentValueSubject<Bool, Never>(true)
    let isValid = CurrentValueSubject<Bool, Never>(false)
    let composeViewModel = ComposeViewModel()
    let characterCount = CurrentValueSubject<Int, Never>(0)

    init() {
        viewDidAppear.receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] viewDidAppear in
                guard let self = self else { return }
                guard viewDidAppear else { return }
                self.setupCoreData()
            }
            .store(in: &disposeBag)

        Publishers.CombineLatest(
            inputItems.removeDuplicates(),
            viewDidAppear.removeDuplicates()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] inputItems, _ in
            guard let self = self else { return }
            self.parse(inputItems: inputItems)
        }
        .store(in: &disposeBag)

        authentication
            .map { result in result == nil }
            .assign(to: \.value, on: isFetchAuthentication)
            .store(in: &disposeBag)

        authentication
            .compactMap { result -> Bool? in
                guard let result = result else { return nil }
                switch result {
                case .success(let authentication):
                    return authentication.user.locked
                case .failure:
                    return nil
                }
            }
            .map { locked -> ComposeToolbarView.VisibilitySelectionType in
                locked ? .private : .public
            }
            .assign(to: \.value, on: selectedStatusVisibility)
            .store(in: &disposeBag)

        isFetchAuthentication
            .receive(on: DispatchQueue.main)
            .assign(to: \.value, on: isBusy)
            .store(in: &disposeBag)

        composeViewModel.statusPlaceholder = L10n.Scene.Compose.contentInputPlaceholder
        composeViewModel.contentWarningPlaceholder = L10n.Scene.Compose.ContentWarning.placeholder
        composeViewModel.toolbarHeight = ComposeToolbarView.toolbarHeight
        
        setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &disposeBag)

        composeViewModel.$characterCount
            .assign(to: \.value, on: characterCount)
            .store(in: &disposeBag)
    }

    private func setupBackgroundColor(theme: Theme) {
        composeViewModel.contentWarningBackgroundColor = Color(theme.contentWarningOverlayBackgroundColor)
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

extension ShareViewModel {
    func parse(inputItems: [NSExtensionItem]) {
        var itemProviders: [NSItemProvider] = []

        for item in inputItems {
            itemProviders.append(contentsOf: item.attachments ?? [])
        }

        let _movieProvider = itemProviders.first(where: { provider in
            return provider.hasRepresentationConforming(toTypeIdentifier: UTType.movie.identifier, fileOptions: [])
        })

        let imageProviders = itemProviders.filter { provider in
            return provider.hasRepresentationConforming(toTypeIdentifier: UTType.image.identifier, fileOptions: [])
        }

        if let movieProvider = _movieProvider {
            composeViewModel.setupAttachmentViewModels([
                StatusAttachmentViewModel(itemProvider: movieProvider)
            ])
        } else {
            let viewModels = imageProviders.map { provider in
                StatusAttachmentViewModel(itemProvider: provider)
            }
            composeViewModel.setupAttachmentViewModels(viewModels)
        }
    }
}
