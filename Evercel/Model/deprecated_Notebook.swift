//
//  Notebook.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 08/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//

import Foundation

struct deprecated_Notebook {
    let name: String
    let creationDate: Date
    let notes: [deprecated_Note]
    
    static let dummyNotebookModel: [deprecated_Notebook] = [
        deprecated_Notebook(name: "Prueba 1", creationDate: Date(), notes: []),
        deprecated_Notebook(name: "Prueba 2", creationDate: Date().calculateDate(fromDaysBefore: 5), notes: []),
        deprecated_Notebook(name: "Prueba 3", creationDate: Date().calculateDate(fromDaysBefore: 7), notes: deprecated_Note.dummyNotesModel),
        deprecated_Notebook(name: "Prueba 4", creationDate: Date().calculateDate(fromDaysBefore: 7), notes: []),
        deprecated_Notebook(name: "Prueba 5", creationDate: Date().calculateDate(fromDaysBefore: 7), notes: deprecated_Note.dummyNotesModel),
        deprecated_Notebook(name: "Prueba 6", creationDate: Date().calculateDate(fromDaysBefore: 8), notes: []),
        deprecated_Notebook(name: "Prueba 7", creationDate: Date().calculateDate(fromDaysBefore: 9), notes: []),
        deprecated_Notebook(name: "Prueba 8", creationDate: Date().calculateDate(fromDaysBefore: 10), notes: [])
    ]
}

extension Date {
    func calculateDate(fromDaysBefore days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: self) ?? Date()
    }
}
