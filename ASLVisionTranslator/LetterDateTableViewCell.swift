//
//  LetterDateTableViewCell.swift
//  ASLVisionTranslator
//
//  Created by Roman Auersvald on 09.12.2020.
//

import UIKit

class LetterDateTableViewCell: UITableViewCell {

    @IBOutlet weak var lblLetter: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
