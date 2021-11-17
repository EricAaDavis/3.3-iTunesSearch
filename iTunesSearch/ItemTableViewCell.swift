
import UIKit

class ItemTableViewCell: UITableViewCell, ItemDisplaying {
    
    @IBOutlet private(set) var itemImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!
    
}
