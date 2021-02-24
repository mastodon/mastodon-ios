//
//  PickServerViewModel.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import UIKit
import Combine
import MastodonSDK

class PickServerViewModel: NSObject {
    enum PickServerMode {
        case SignUp
        case SignIn
    }
    
    enum Section: CaseIterable {
        case title
        case categories
        case search
        case serverList
    }
    
    enum Category {
        // `All` means search for all categories
        case All
        // `Some` means search for specific category
        case Some(Mastodon.Entity.Category)
        
        var title: String {
            switch self {
            case .All:
                return L10n.Scene.ServerPicker.Button.Category.all
            case .Some(let masCategory):
                // TODO: Use emoji as placeholders
                switch masCategory.category {
                case .academia:
                    return "📚"
                case .activism:
                    return "✊"
                case .food:
                    return "🍕"
                case .furry:
                    return "🦁"
                case .games:
                    return "🕹"
                case .general:
                    return "GE"
                case .journalism:
                    return "📰"
                case .lgbt:
                    return "🏳️‍🌈"
                case .regional:
                    return "📍"
                case .art:
                    return "🎨"
                case .music:
                    return "🎼"
                case .tech:
                    return "📱"
                case ._other:
                    return "❓"
                }
            }
        }
    }
    
    let mode: PickServerMode
    let context: AppContext
    
    var categories = [Category]()
    let selectCategoryIndex = CurrentValueSubject<Int, Never>(0)
    
    let searchText = CurrentValueSubject<String?, Never>(nil)
    
    let allServers = CurrentValueSubject<[Mastodon.Entity.Server], Never>([])
    let searchedServers = CurrentValueSubject<[Mastodon.Entity.Server], Error>([])
    
    let nextButtonEnable = CurrentValueSubject<Bool, Never>(false)
    
    private var disposeBag = Set<AnyCancellable>()
    
    weak var tableView: UITableView?
    
    init(context: AppContext, mode: PickServerMode) {
        self.context = context
        self.mode = mode
        super.init()
        
        configure()
    }
    
    private func configure() {
        let masCategories = context.apiService.stubCategories()
        categories.append(.All)
        categories.append(contentsOf: masCategories.map { Category.Some($0) })
        
        Publishers.CombineLatest3(
            selectCategoryIndex,
            searchText.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main).removeDuplicates(),
            allServers
        )
        .flatMap { [weak self] (selectCategoryIndex, searchText, allServers) -> AnyPublisher<[Mastodon.Entity.Server], Error> in
            guard let self = self else { return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher() }
            
            // 1. Search from the servers recorded in joinmastodon.org
            let searchedServersFromAPI = self.searchServersFromAPI(category: self.categories[selectCategoryIndex], searchText: searchText, allServers: allServers)
            if !searchedServersFromAPI.isEmpty {
                // If found servers, just return
                return Just(searchedServersFromAPI).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            // 2. No server found in the recorded list, check if searchText is a valid mastodon server domain
            if let toSearchText = searchText, !toSearchText.isEmpty {
                return self.context.apiService.instance(domain: toSearchText)
                    .map { return [Mastodon.Entity.Server(instance: $0.value)] }.eraseToAnyPublisher()
            }
            return Just(searchedServersFromAPI).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        .sink { completion in
            print("1")
        } receiveValue: { [weak self] servers in
            self?.searchedServers.send(servers)
        }
        .store(in: &disposeBag)

        
    }
    
    func fetchAllServers() {
        context.apiService.servers(language: nil, category: nil)
            .receive(on: DispatchQueue.main)
            .sink { error in
                print("11")
            } receiveValue: { [weak self] result in
                self?.allServers.send(result.value)
            }
            .store(in: &disposeBag)
        
    }
    
    private func searchServersFromAPI(category: Category, searchText: String?, allServers: [Mastodon.Entity.Server]) -> [Mastodon.Entity.Server] {
        return allServers
            // 1. Filter the category
            .filter {
                switch category {
                case .All:
                    return true
                case .Some(let masCategory):
                    return $0.category.caseInsensitiveCompare(masCategory.category.rawValue) == .orderedSame
                }
            }
            // 2. Filter the searchText
            .filter {
                if let searchText = searchText {
                    return $0.domain.contains(searchText)
                } else {
                    return true
                }
            }
    }
}

extension PickServerViewModel: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let category = Section.allCases[section]
        switch category {
        case .title:
            return 20
        case .categories:
            // Since category view has a blur shadow effect, its height need to be large than the actual height,
            // Thus we reduce the section header's height by 10, and make the category cell height 60+20(10 inset for top and bottom)
            return 10
        case .search:
            // Same reason as above
            return 10
        case .serverList:
            // Header with 1 height as the separator
            return 1
        }
    }
    
}

extension PickServerViewModel: UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Self.Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Self.Section.allCases[section]
        switch section {
        case .title,
             .categories,
             .search:
            return 1
        case .serverList:
            return searchedServers.value.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = Self.Section.allCases[indexPath.section]
        switch section {
        case .title:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerTitleCell.self), for: indexPath) as! PickServerTitleCell
            return cell
        case .categories:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerCategoriesCell.self), for: indexPath) as! PickServerCategoriesCell
            cell.dataSource = self
            cell.delegate = self
            return cell
        case .search:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerSearchCell.self), for: indexPath) as! PickServerSearchCell
            cell.delegate = self
            return cell
        case .serverList:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerCell.self), for: indexPath) as! PickServerCell
            cell.server = searchedServers.value[indexPath.row]
            cell.delegate = self
            return cell
        }
    }
}

extension PickServerViewModel: PickServerCategoriesDataSource, PickServerCategoriesDelegate {
    func numberOfCategories() -> Int {
        return categories.count
    }
    
    func category(at index: Int) -> Category {
        return categories[index]
    }
    
    func selectedIndex() -> Int {
        return selectCategoryIndex.value
    }
    
    func pickServerCategoriesCell(didSelect index: Int) {
        selectCategoryIndex.send(index)
    }
}

extension PickServerViewModel: PickServerSearchCellDelegate {
    func pickServerSearchCell(didChange searchText: String?) {
        self.searchText.send(searchText)
    }
}

extension PickServerViewModel: PickServerCellDelegate {
    func pickServerCell(modeChange updates: (() -> Void)) {
        tableView?.beginUpdates()
        tableView?.performBatchUpdates(updates, completion: nil)
        tableView?.endUpdates()
    }
}
