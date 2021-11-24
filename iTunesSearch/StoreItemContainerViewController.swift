
import UIKit

class StoreItemContainerViewController: UIViewController, UISearchResultsUpdating {
    
    @IBOutlet var tableContainerView: UIView!
    @IBOutlet var collectionContainerView: UIView!
    
    let searchController = UISearchController()
    let storeItemController = StoreItemController()
    
    
    private var selectedSearchScope: SearchScope {
        let selectedIndex = searchController.searchBar.selectedScopeButtonIndex
        let searchScope = SearchScope.allCases[selectedIndex]
        
        return searchScope
    }
    
    
    var tableViewDataSource: UITableViewDiffableDataSource<String, StoreItem>!
    func configureTableViewDataSource(_ tableView: UITableView) {
        
        

        
        tableViewDataSource = StoreItemTableDiffableDataSource(tableView: tableView, storeItemController: storeItemController)
        /*
        UITableViewDiffableDataSource<String, StoreItem>(tableView: tableView, cellProvider: { (tableView, indexPath, item) -> UITableViewCell? in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath) as! ItemTableViewCell
            cell.configure(for: item, storeItemController: self.storeItemController)
            return cell
        })
         */
    }
    
    var collectionViewDataSource: UICollectionViewDiffableDataSource<String, StoreItem>!
    func configureCollectionViewDataSource(_ collectionView: UICollectionView) {
        collectionViewDataSource = UICollectionViewDiffableDataSource<String, StoreItem>(collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Item", for: indexPath) as! ItemCollectionViewCell
            cell.configure(for: item, storeItemController: self.storeItemController)
            return cell
            
        })
        
        collectionViewDataSource.supplementaryViewProvider = { collectionView, kind, indexPath -> UICollectionReusableView? in
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: "Header", withReuseIdentifier: StoreItemCollectionViewSectionHeader.reuseIdentifier, for: indexPath) as! StoreItemCollectionViewSectionHeader
            
            let title = self.itemsSnapshot.sectionIdentifiers[indexPath.section]
            headerView.setTitle(title)
            
            return headerView
            
        }
        
    }
    
    var itemsSnapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
    /*
    {
        var snapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
        
        //Add a computed property to create this from the items array. There should be a single section in the snapshot.
        for item in items {
            snapshot.appendSections([String(item.hashValue)])
            snapshot.appendItems(items, toSection: nil)
        }
        return snapshot
        
    }
     */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tableViewController = segue.destination as? StoreItemListTableViewController {
            configureTableViewDataSource(tableViewController.tableView)
        } else if let collectionViewController = segue.destination as? StoreItemCollectionViewController {
            //collectionViewController.configureCollectionViewLayout(for: selectedSearchScope)
            
            configureCollectionViewDataSource(collectionViewController.collectionView)
            
        }
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true

        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.automaticallyShowsSearchResultsController = true
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.scopeButtonTitles = SearchScope.allCases.map { $0.title }
        searchController.searchBar.text = "Coldplay"
    }
    
    // DEBOUNCE
    func updateSearchResults(for searchController: UISearchController) {
        let selector = #selector(fetchMatchingItems)
        
        // Don't call the selector function for the previous input
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: selector, object: nil)
        
        //Since we don't want to fetch items on every keystroke, we fetch it after it has been 0.3 seconds since the last keystroke
        perform(selector, with: nil, afterDelay: 0.3)
    }
                
    @IBAction func switchContainerView(_ sender: UISegmentedControl) {
        //collectionView.numberOfItemsPerRow = 1 || 3
        tableContainerView.isHidden.toggle()
        collectionContainerView.isHidden.toggle()
    }
    
    func handleFetchedItems(_ items: [StoreItem]) {
        let currentSnapshotItems = itemsSnapshot.itemIdentifiers
        itemsSnapshot = createSectionedSnapshot(from: currentSnapshotItems + items)
        
        tableViewDataSource.apply(itemsSnapshot, animatingDifferences: true, completion: nil)
        collectionViewDataSource.apply(itemsSnapshot, animatingDifferences: true, completion: nil)
    }
    
    func createSectionedSnapshot(from items: [StoreItem]) -> NSDiffableDataSourceSnapshot<String, StoreItem> {
        
        let movies = items.filter { $0.kind == "feature-movie" }
        let music = items.filter { $0.kind == "song" || $0.kind == "album" }
        let apps = items.filter { $0.kind == "software" }
        let books = items.filter { $0.kind == "ebook" }
        
        let grouped: [(SearchScope, [StoreItem])] = [
            (.movies, movies),
            (.music, music),
            (.apps, apps),
            (.books, books)
        ]
        
        var snapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
        grouped.forEach { (scope, items) in
            if items.count > 0 {
                snapshot.appendSections([scope.title])
                snapshot.appendItems(items, toSection: scope.title)
            }
        }
        
        return snapshot
    }
    
    @objc func fetchMatchingItems() {
        itemsSnapshot.deleteAllItems()
        
        
        let searchTerm = searchController.searchBar.text ?? ""
        
        
        if !searchTerm.isEmpty {
            
            //if the selected search schope is equal to .all return all for searchScopes, otherwise return the respective search scope
            let searchScopes: [SearchScope]
            if selectedSearchScope == .all {
                searchScopes = [.movies, .music, .apps, .books]
            } else {
                searchScopes = [selectedSearchScope]
            }
            
            
            for searchScope in searchScopes {
                // set up query dictionary
                let query = [
                    "term": searchTerm,
                    "media": searchScope.mediaType,
                    "lang": "en_us",
                    "limit": "20"
                ]
                
                // use the item controller to fetch items
                storeItemController.fetchItems(matching: query) { (result) in
                    switch result {
                    case .success(let items):
                        // if successful, use the main queue to set self.items and reload the table view
                        DispatchQueue.main.async {
                            guard searchTerm == self.searchController.searchBar.text else {
                                return
                            }
                            
                                                
                            self.handleFetchedItems(items)
                        }
                    case .failure(let error):
                        // otherwise, print an error to the console
                        print(error)
                    }
                }
            }
        }
    }
}
