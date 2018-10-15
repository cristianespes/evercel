//
//  NotebookListCell.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 08/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//

import UIKit

class NotebookListCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var creationDateLabel: UILabel!
    
    override func prepareForReuse() {
        titleLabel.text = nil
        creationDateLabel.text = nil
        
        super.prepareForReuse()
    }
    
    //func configure(with notebook: deprecated_Notebook) {
    func configure(with notebook: Notebook) {
        titleLabel.text = notebook.name
        creationDateLabel.text = "\((notebook.creationDate as Date?)?.customStringLabel() ?? "Not available")"
    }
}
