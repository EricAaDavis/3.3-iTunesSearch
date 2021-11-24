//
//  StoreItemTableViewDiffableDataSource.swift
//  iTunesSearch
//
//  Created by Eric Davis on 23/11/2021.
//

import Foundation
import UIKit

class StoreItemTableDiffableDataSource: UITableViewDiffableDataSource<String, StoreItem> {
    
    init(tableView: UITableView, storeItemController: StoreItemController) {
        super.init(tableView: tableView) {
            (tableView, indexPath, item) -> UITableViewCell? in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath) as! ItemTableViewCell
            cell.configure(for: item, storeItemController: storeItemController)
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return snapshot().sectionIdentifiers[section]
    }
    
}


