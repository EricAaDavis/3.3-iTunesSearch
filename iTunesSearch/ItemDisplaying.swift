//
//  ItemDisplaying.swift
//  iTunesSearch
//
//  Created by Eric Davis on 16/11/2021.
//

import UIKit

protocol ItemDisplaying {
    var itemImageView: UIImageView! { get }
    var titleLabel: UILabel! { get }
    var detailLabel: UILabel! { get }
}


extension ItemDisplaying {
    func configure(for item: StoreItem, storeItemController: StoreItemController) {
        titleLabel.text = item.name
        detailLabel.text = item.artist
        itemImageView.image = UIImage(systemName: "photo")
        
        storeItemController.fetchImage(from: item.artworkURL) { result in
            switch result {
            case .success(let image):
                DispatchQueue.main.async {
                    itemImageView.image = nil
                    itemImageView.image = image
                }
                
            case .failure(let error):
                print("Unable to fetch image: \(error)")
            }
        }
    }
}
