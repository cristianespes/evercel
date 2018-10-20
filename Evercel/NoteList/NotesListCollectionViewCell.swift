//
//  NotesListCollectionViewCell.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 12/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//

import UIKit

class NotesListCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var item: Note!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with item: Note) {
        //backgroundColor = .burlywood
        titleLabel.text = item.title
        if let data = item.image as Data? {
            imageView.image = UIImage(data: data)
            titleLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
            creationDateLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
        } else {
            imageView.image = UIImage(named: "120x180")
        }
        imageView.contentMode = .scaleAspectFill
        creationDateLabel.text = (item.creationDate as Date?)?.customStringLabel()
    }

}
