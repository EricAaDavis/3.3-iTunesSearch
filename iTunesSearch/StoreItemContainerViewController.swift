
import UIKit

class StoreItemContainerViewController: UIViewController, UISearchResultsUpdating {
    
    @IBOutlet var tableContainerView: UIView!
    @IBOutlet var collectionContainerView: UIView!
    
    let searchController = UISearchController()
    let storeItemController = StoreItemController()
    weak var collectionViewController: StoreItemCollectionViewController?
    var selectedSearchScope: SearchScope {
        let selectedIndex = searchController.searchBar.selectedScopeButtonIndex
        let searchScope = SearchScope.allCases[selectedIndex]
        
        return searchScope
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
        searchController.searchBar.text = "Swift"
    }
    
    @IBAction func switchContainerView(_ sender: UISegmentedControl) {
        //collectionView.numberOfItemsPerRow = 1 || 3
        tableContainerView.isHidden.toggle()
        collectionContainerView.isHidden.toggle()
    }
    
    //MARK: Table View Data Source
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
    
    //MARK: Collection View Data Source
    var collectionViewDataSource: UICollectionViewDiffableDataSource<String, StoreItem>!
    func configureCollectionViewDataSource(_ collectionView: UICollectionView) {
        collectionViewDataSource = UICollectionViewDiffableDataSource<String, StoreItem>(collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Item", for: indexPath) as! ItemCollectionViewCell
            cell.configure(for: item, storeItemController: self.storeItemController)
            return cell
        })
        
        
        //How does it know what collection view we are providing the eaders? is it in configureCollectionViewLayout(), section.boundarySupplementaryItems = [headerItem]
        collectionViewDataSource.supplementaryViewProvider = { collectionView, kind, indexPath -> UICollectionReusableView? in
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: StoreItemCollectionViewSectionHeader.reuseIdentifier, for: indexPath) as! StoreItemCollectionViewSectionHeader
            
            let title = self.itemsSnapshot.sectionIdentifiers[indexPath.section]
            headerView.setTitle(title)
            
            return headerView
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tableViewController = segue.destination as? StoreItemListTableViewController {
            configureTableViewDataSource(tableViewController.tableView)
        } else if let collectionViewController = segue.destination as? StoreItemCollectionViewController {
            self.collectionViewController = collectionViewController
            //configure the collection view for the passed in collection view
            collectionViewController.configureCollectionViewLayout(for: selectedSearchScope)
            configureCollectionViewDataSource(collectionViewController.collectionView)

            
        }
    }
    
    // DEBOUNCE
    func updateSearchResults(for searchController: UISearchController) {
        
        
        let selector = #selector(fetchMatchingItems)
        
        // Don't call the selector function for the previous input
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: selector, object: nil)
        
        //Since we don't want to fetch items on every keystroke, we fetch it after it has been 0.3 seconds since the last keystroke
        //0.3 seconds is considered to be just a perfect delay, anything more and the user feels bored, anything less and requests are sent too often
        perform(selector, with: nil, afterDelay: 0.3)
    }
    
    var itemsSnapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
    
    func handleFetchedItems(_ items: [StoreItem]) {
        //MARK: Handle fetched items, apply snapshot
        let currentSnapshotItems = itemsSnapshot.itemIdentifiers
        
        //Create sectioned snapshot from the current snapshot + the new items
        //Why do we need to add currentSnapshotItems + the new items? Don't we get all new items every time and need to update the whole table view?
        itemsSnapshot = createSectionedSnapshot(from: currentSnapshotItems + items)
        
        tableViewDataSource.apply(itemsSnapshot, animatingDifferences: true, completion: nil)
        collectionViewDataSource.apply(itemsSnapshot, animatingDifferences: true, completion: nil)
        
        collectionViewController?.configureCollectionViewLayout(for: selectedSearchScope)
    }
    
    func createSectionedSnapshot(from items: [StoreItem]) -> NSDiffableDataSourceSnapshot<String, StoreItem> {
        //MARK: Create the sectioined snapshot
        
        //If the current items contains the kind lable we are looking for, then add it to the array
        let movies = items.filter { $0.kind == "feature-movie" }
        let podcast = items.filter { $0.kind == "podcast" }
        let music = items.filter { $0.kind == "song" || $0.kind == "album" }
        let apps = items.filter { $0.kind == "software" }
        let books = items.filter { $0.kind == "ebook" }
        
        //here we group the kind arrays in a tuple with the respectable media type from the SearchScope enumeration
        let grouped: [(SearchScope, [StoreItem])] = [
            (.movies, movies),
            (.podcast, podcast),
            (.music, music),
            (.apps, apps),
            (.books, books)
        ]
        
        //initialize a snapshot taking a parameter of string(Section identifier) and StoreItem(appending all the store items for the respectable section identifier)
        var snapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
        
        grouped.forEach { (scope, items) in
            //Loop thrrough all items in each section appending it to the snapshot as long as it has at least one item
            if items.count > 0 {
                //snapshot.appendSections(["Movies"])
                //add a snapshot section
                snapshot.appendSections([scope.title])
                //append the items to the respectable section
                //snapshot.appendItems(items, toSection: "Movies")
                snapshot.appendItems(items, toSection: scope.title)
            }
        }
         // return the snapshot and apply it to the collectionViewDataSource or tableViewDataSource
        return snapshot
    }
    
    @objc func fetchMatchingItems() {
        //MARK: Create a data request
        
        itemsSnapshot.deleteAllItems()
        
        
        let searchTerm = searchController.searchBar.text ?? ""
        
        
        if !searchTerm.isEmpty {
            
            //if the selected search schope is equal to .all return all for searchScopes, otherwise return the respective search scope
            let searchScopes: [SearchScope]
            if selectedSearchScope == .all {
                searchScopes = [.movies, .podcast, .music, .apps, .books]
            } else {
                searchScopes = [selectedSearchScope]
            }
            
            //we loop through the search scope to get the desired media type in our data request
            for searchScope in searchScopes {
                // set up query dictionary
                let query = [
                    //We use the search term from the text field to get the desired content
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
                            //What does it mean when this is only a guard and not guard let? Is it to break out of the funciont in case search term != the text in the searchBar?
                            guard searchTerm == self.searchController.searchBar.text else {
                                return
                            }
                            
                            //when we get data back, we pass it in to handleFetchedItems(items:) to apply the snapshot to the table view or the collection view
                            //Items is an array of StoreItems
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
