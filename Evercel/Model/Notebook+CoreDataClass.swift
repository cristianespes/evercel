//
//  Notebook+CoreDataClass.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 09/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Notebook)
public class Notebook: NSManagedObject {

}

extension Notebook {
    func csv() -> String {
        let exportedTitle = name ?? "Sin título"
        let exportedCreationDate = (creationDate as Date?)?.customStringLabel() ?? "Fecha no disponible"
        let exportedNotes = notes?.count ?? 0
        
        return "Notebook: \(exportedTitle),\nCreado el: \(exportedCreationDate),\nContiene un total de \(exportedNotes) notas.\n\n"
    }
}
