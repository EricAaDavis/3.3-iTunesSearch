//
//  ItemCollectionViewCell.swift
//  iTunesSearch
//
//  Created by Eric Davis on 16/11/2021.
//

import UIKit

class ItemCollectionViewCell: UICollectionViewCell, ItemDisplaying {

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    
}
