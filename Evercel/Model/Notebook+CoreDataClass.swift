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
    
    @objc var stringCreationDate: NSString {
        let formatter = DateFormatter()
        // initially set the format based on your datepicker date / server String
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let myString = formatter.string(from: creationDate! as Date)
        
        // convert your string to date
        let myDate = formatter.date(from: myString)
        //then again set the date format whhich type of output you need
        formatter.dateFormat = "dd-MMM-yyyy"
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        // again convert your date to string
        let myStringafd = formatter.string(from: myDate!)
        
        return myStringafd as NSString
    }
    
    func csv() -> String {
        let exportedTitle = name ?? "Sin título"
        let exportedCreationDate = (creationDate as Date?)?.customStringLabel() ?? "Fecha no disponible"
        let exportedNotes = notes?.count ?? 0
        
        return "Notebook: \(exportedTitle),\nCreado el: \(exportedCreationDate),\nContiene un total de \(exportedNotes) notas.\n\n"
    }
}
