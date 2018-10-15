//
//  Note+CoreDataClass.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 15/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Note)
public class Note: NSManagedObject {
    
}

extension Note {
    func csv() -> String {
        let exportedTitle = title ?? "Sin título"
        let exportedText = text ?? ""
        let exportedCreationDate = (creationDate as Date?)?.customStringLabel() ?? "Not available"
        
        return "\(exportedCreationDate),\(exportedTitle),\(exportedText)"
    }
}
