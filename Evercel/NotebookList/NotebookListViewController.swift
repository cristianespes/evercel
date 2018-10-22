//
//  NotebookListViewController.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 08/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//

import UIKit
import CoreData

class NotebookListViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalLabel: UILabel!
    
    // MARK: - Properties
    var coreDataStack: CoreDataStack!
    private var fetchedResultsController: NSFetchedResultsController<Notebook>!
    
    private func getFetchedResultsController(with predicate: NSPredicate = NSPredicate(value: true)) -> NSFetchedResultsController<Notebook> {
        
        let fetchRequest: NSFetchRequest<Notebook> = Notebook.fetchRequest()
        fetchRequest.predicate = predicate
        
        let sort = NSSortDescriptor(key: #keyPath(Notebook.creationDate), ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: coreDataStack.managedContext,
            sectionNameKeyPath: #keyPath(Notebook.creationDate),
            cacheName: nil)
    }
    
    private func setNewFetchedResultController(_ newFrc: NSFetchedResultsController<Notebook>) {
        let oldFrc = fetchedResultsController
        if (newFrc != oldFrc) {
            fetchedResultsController = newFrc
            newFrc.delegate = self
            do {
                try fetchedResultsController.performFetch()
            } catch let error as NSError {
                print("Could not fetch \(error.localizedDescription)")
            }
            tableView.reloadData()
        }
    }
    
    // MARK: - Lyfe Cycle
    override func viewDidLoad() {
//        navigationController?.navigationBar.prefersLargeTitles = true
//        navigationController?.navigationItem.largeTitleDisplayMode = .always
        
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        
        configureSearchController()
        
        showAll()
    }
    
    // MARK: - Helper methods
    private func configureSearchController() {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self // Objeto responsable de actualizar los resultados
        search.obscuresBackgroundDuringPresentation = false // quiero mostrar toda la tabla
        search.searchBar.placeholder = "Search Notebook..."
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
    }
    
    private func populateTotalLabel(with predicate: NSPredicate = NSPredicate(value: true)) {
        let fetchRequest = NSFetchRequest<NSNumber>(entityName: "Notebook")
        fetchRequest.resultType = .countResultType
        
        fetchRequest.predicate = predicate
        
        do {
            let countResult = try coreDataStack.managedContext.fetch(fetchRequest)
            let count = countResult.first!.intValue
            totalLabel.text = "\(count)"
        } catch let error as NSError {
            print("Count not fetch: \(error)")
        }
    }
    
    @IBAction func shareNotebooks(_ sender: UIBarButtonItem) {
        coreDataStack.storeContainer.performBackgroundTask { [unowned self] (context) in

            var notebookResults: [Notebook] = []
            
            do {
                // Recogemos la información de la BBDD
                notebookResults = try self.coreDataStack.managedContext.fetch(self.notebooksFetchRequest())
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
            }

            let exportPath = NSTemporaryDirectory() + "notebooks.csv"
            let exportURL = URL(fileURLWithPath: exportPath)
            
            FileManager.default.createFile(atPath: exportPath, contents: Data(), attributes: nil)
            
            let fileHandle: FileHandle?
            do {
                // Inicialización de fileHandle
                fileHandle = try FileHandle(forWritingTo: exportURL)
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
                fileHandle = nil
            }

            if let fileHandle = fileHandle {
                for notebook in notebookResults {
                    fileHandle.seekToEndOfFile() // Añadir al final del archivo
                    guard let csvData = notebook.csv().data(using: .utf8, allowLossyConversion: false) else { return }
                    fileHandle.write(csvData)
                    
                    for note in notebook.notes! {
                        fileHandle.seekToEndOfFile()
                        guard let csvData = (note as! Note).csv().data(using: .utf8, allowLossyConversion: false) else { return }
                        fileHandle.write(csvData)
                    }
                }
                
                fileHandle.closeFile()
                
                do {
                    // Exportar contenido en formato texto
//                    let stringData = try String(contentsOf: exportURL, encoding: String.Encoding.utf8)
//                    DispatchQueue.main.async { [weak self] in
//                        self?.showExportFinishedAlert(file: stringData)
//                    }
                    // Exportar fichero CSV
                    let csvData = try Data(contentsOf: exportURL)
                    DispatchQueue.main.async { [weak self] in
                        self?.showExportFinishedAlert(file: csvData)
                    }
                } catch let error as NSError {
                    print("Error: \(error.localizedDescription)")
                }
                
            } else {
                print("No ha sido posible exportar los datos")
            }
        }

    }
    
    private func showExportFinishedAlert(file: Any) {
        let activityViewController = UIActivityViewController(activityItems: [file], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.postToFacebook ]
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    private func notebooksFetchRequest() -> NSFetchRequest<Notebook> {
        let fetchRequest: NSFetchRequest<Notebook> = Notebook.fetchRequest()
        fetchRequest.fetchBatchSize = 50
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        return fetchRequest
    }
    
    
    @IBAction func addNotebook(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Nuevo Notebook", message: "Añadir un nuevo Notebook", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Guardar", style: .default) { [unowned self] action in
            guard let textField = alert.textFields?.first, let nameToSave = textField.text else { return }
            
            let notebook = Notebook(context: self.coreDataStack.managedContext) // Crea el entity (inicializo una clase de CoreData)
            notebook.name = nameToSave
            notebook.creationDate = NSDate()
            
            do {
                try self.coreDataStack.managedContext.save() // Guarda
            } catch let error as NSError {
                print("TODO error handling")
                print(error.localizedDescription)
            }
            
            //self.tableView.reloadData()
            //self.reloadView()
            self.showAll()
        }
        
        let cancelAction = UIAlertAction(title: "Cancelar", style: .default)
        
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
}

// MARK: - UITableViewDataSource
extension NotebookListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let section = fetchedResultsController.sections else { return 1 }
        return section.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultsController.sections?[section] else { return 0 }
        
        return sectionInfo.numberOfObjects
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotebookListCell", for: indexPath) as! NotebookListCell
        
//        cell.configure(with: model[indexPath.row])
        //let notebook = dataSource[indexPath.row] as! Notebook
        let notebook = fetchedResultsController.object(at: indexPath)
        
        cell.configure(with: notebook)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension NotebookListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notebook = fetchedResultsController.object(at: indexPath)
        
//        let notesListVC = NewNotesListViewController(notebook: notebook, coreDataStack: coreDataStack)
//        show(notesListVC, sender: nil)
        
        
        //let notesMapVC = NotesMapViewController(notebook: notebook, coreDataStack: coreDataStack)
        //show(notesMapVC, sender: nil)
        
    //navigationController?.pushViewController(PresentNotesViewController(notebook: notebook, coreDataStack: coreDataStack), animated: true)
        
        
        
        
        
//        let tabBarController = UITabBarController()
//
//        let notesListVC = NewNotesListViewController(notebook: notebook, coreDataStack: coreDataStack)
//        let notesMapVC = NotesMapViewController(notebook: notebook, coreDataStack: coreDataStack)
        
//        let notesListNC = UINavigationController(rootViewController: notesListVC)
//        let notesMapNC = UINavigationController(rootViewController: notesMapVC)
        
//        tabBarController.viewControllers = [notesListVC, notesMapVC]
//
//        tabBarController.navigationController?.isNavigationBarHidden = true
//        tabBarController.navigationController?.isToolbarHidden = true
//
//        tabBarController.tabBar.items![0].title = notesListVC.title?.uppercased()
//        tabBarController.tabBar.items![1].title = notesMapVC.title?.uppercased()
//        tabBarController.tabBar.items![0].image = UIImage(named: "ShieldIcon")
//        tabBarController.tabBar.items![1].image = UIImage(named: "ShieldIcon")
        
        //show(tabBarController, sender: nil)
        
        
        //navigationController?.pushViewController(tabBarController, animated: true)
        
        
        
        //show(PresentNotesVC(notebook: notebook, coreDataStack: coreDataStack), sender: nil)
        navigationController?.pushViewController(PresentNotesVC(notebook: notebook, coreDataStack: coreDataStack), animated: true)
        
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections?[section]
        
        guard let dateString = sectionInfo?.name else { return sectionInfo?.name }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        let date = dateFormatter.date(from: dateString)
        //print("date: \(date?.customStringLabel())")
//        dateFormatter.dateFormat = "dd/MM/yyyy"
//        let sectionDate = dateFormatter.string(from:date!)
        
        return date?.customStringLabel()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Eliminar Notebook
//        guard let notebookToRemove = dataSource[indexPath.row] as? Notebook, editingStyle == .delete else { return }
        
        guard editingStyle == .delete else { return }
        
        let notebookToRemove = fetchedResultsController.object(at: indexPath)
        
        coreDataStack.managedContext.delete(notebookToRemove)
        
        do {
            try coreDataStack.managedContext.save()
            //tableView.deleteRows(at: [indexPath], with: .automatic)
        } catch let error as NSError{
            print("Error: \(error.localizedDescription)")
        }
        
        showAll()
    }
}

// MARK: - UISearchResultsUpdating implmentation
extension NotebookListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text, !text.isEmpty {
            // Mostrar resultados filtrados
            showFilteredResults(with: text)
        } else {
            // Mostrar todos los resultados
            showAll()
        }
    }
    
    private func showFilteredResults(with query: String) {
        let predicate = NSPredicate(format: "name CONTAINS[c] %@", query)
        let frc = getFetchedResultsController(with: predicate)
        setNewFetchedResultController(frc)
        
        populateTotalLabel(with: predicate)
        
    }
    
    private func showAll() {
        let frc = getFetchedResultsController()
        setNewFetchedResultController(frc)
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Could not fetch \(error.localizedDescription)")
        }
        
        populateTotalLabel()
    }
}

// MARK: - NSFetchedResultsControllerDelegate implementation
extension NotebookListViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            tableView.insertSections(indexSet, with: .automatic)
        case .delete:
            tableView.deleteSections(indexSet, with: .automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
