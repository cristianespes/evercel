//
//  CoreDataStack.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 09/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    private let modelName: String
    
    lazy var managedContext: NSManagedObjectContext = {
        return self.storeContainer.viewContext
    }()
    
    /*lazy var backgroundContext: NSManagedObjectContext = {
       return self.storeContainer.newBackgroundContext()
    }()*/ // Puede ser usado en lugar de perfomBackgroundTask de NSPersistentContainer
    
    init(modelName: String) {
        self.modelName = modelName
    }
    
    /*private*/ lazy var storeContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.modelName)
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Unresolved  error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    func saveContext() {
        guard managedContext.hasChanges else { return }
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Unresolved error \(error), \(error.userInfo)")
        }
    }
}
