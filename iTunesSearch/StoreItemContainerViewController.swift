
import UIKit

class StoreItemContainerViewController: UIViewController, UISearchResultsUpdating {
    
    @IBOutlet var tableContainerView: UIView!
    @IBOutlet var collectionContainerView: UIView!
    
    let searchController = UISearchController()
    let storeItemController = StoreItemController()
    
    var items = [StoreItem]()
    
    let queryOptions = ["movie", "music", "software", "ebook"]
    
    var tableViewDataSource: UITableViewDiffableDataSource<String, StoreItem>!
    func configureTableViewDataSource(_ tableView: UITableView) {
        tableViewDataSource = UITableViewDiffableDataSource<String, StoreItem>(tableView: tableView, cellProvider: { (tableView, indexPath, item) -> UITableViewCell? in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath) as! ItemTableViewCell
            cell.configure(for: item, storeItemController: self.storeItemController)
            return cell
        })
    }
    
    var collectionViewDataSource: UICollectionViewDiffableDataSource<String, StoreItem>!
    func configureCollectionViewDataSource(_ collectionView: UICollectionView) {
        collectionViewDataSource = UICollectionViewDiffableDataSource<String, StoreItem>(collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Item", for: indexPath) as! ItemCollectionViewCell
            cell.configure(for: item, storeItemController: self.storeItemController)
            return cell
            
        })
    }
    
    var itemsSnapshot: NSDiffableDataSourceSnapshot<String, StoreItem> {
        var snapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
        
        //Add a computed property to create this from the items array. There should be a single section in the snapshot.
        for item in items {
            snapshot.appendSections([String(item.trackId!)])
            snapshot.appendItems(items, toSection: nil)
        }
        return snapshot
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tableViewController = segue.destination as? StoreItemListTableViewController {
            configureTableViewDataSource(tableViewController.tableView)
        } else if let collectionViewController = segue.destination as? StoreItemCollectionViewController {
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
        searchController.searchBar.scopeButtonTitles = ["Movies", "Music", "Apps", "Books"]
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(fetchMatchingItems), object: nil)
        
        //Since we don't want to fetch items on every keystroke, we fetch it after it has been 0.3 seconds since the last keystroke
        perform(#selector(fetchMatchingItems), with: nil, afterDelay: 0.3)
    }
                
    @IBAction func switchContainerView(_ sender: UISegmentedControl) {
        tableContainerView.isHidden.toggle()
        collectionContainerView.isHidden.toggle()
    }
    
    @objc func fetchMatchingItems() {
        
        self.items = []
                
        let searchTerm = searchController.searchBar.text ?? ""
        let mediaType = queryOptions[searchController.searchBar.selectedScopeButtonIndex]
        
        if !searchTerm.isEmpty {
            
            // set up query dictionary
            let query = [
                "term": searchTerm,
                "media": mediaType,
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
                        
                        self.items = items
                        
                        // apply data source changes
                        self.tableViewDataSource.apply(self.itemsSnapshot, animatingDifferences: true, completion: nil)
                        self.collectionViewDataSource.apply(self.itemsSnapshot, animatingDifferences: true)
                    }
                case .failure(let error):
                    // otherwise, print an error to the console
                    print(error)
                }
            }
        } else {
            // apply data source changes
            self.tableViewDataSource.apply(self.itemsSnapshot, animatingDifferences: true, completion: nil)
            self.collectionViewDataSource.apply(self.itemsSnapshot, animatingDifferences: true)
        }
    }
    
}
