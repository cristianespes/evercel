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
        let exportedText = text ?? "Sin contenido"
        let exportedCreationDate = (creationDate as Date?)?.customStringLabel() ?? "Fecha no disponible"
        let exportedTag = tag ?? "Sin etiqueta"
        let exportedCoordinates = (latitude != 0 && longitude != 0) ? "Latitud: \(latitude), Longitud: \(longitude)" : "Coordenadas no disponibles"
        
        return "Nota: \(exportedTitle),\nContenido: \(exportedText),\nEtiqueta: \(exportedTag),\nCoordenadas: \(exportedCoordinates),\nCreado el: \(exportedCreationDate).\n\n"
    }
}
