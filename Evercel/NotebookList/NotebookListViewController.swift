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
    
    var managedContext: NSManagedObjectContext! // Beware to have a value before presenting the VC
    
//    var model: [deprecated_Notebook] = [] {
//        didSet {
//            tableView.reloadData()
//        }
//    }
    
//    var dataSource: [NSManagedObject] = [] {
//        didSet {
//            tableView.reloadData()
//        }
//    }
    
    private var fetchedResultsController: NSFetchedResultsController<Notebook>!
    
    private func getFetchedResultsController(with predicate: NSPredicate = NSPredicate(value: true)) -> NSFetchedResultsController<Notebook> {
        
        let fetchRequest: NSFetchRequest<Notebook> = Notebook.fetchRequest()
        fetchRequest.predicate = predicate
        
        let sort = NSSortDescriptor(key: #keyPath(Notebook.creationDate), ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedContext,
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
    
    override func viewDidLoad() {
//        model = deprecated_Notebook.dummyNotebookModel
        
//        navigationController?.navigationBar.prefersLargeTitles = true
//        navigationController?.navigationItem.largeTitleDisplayMode = .always
        
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        configureSearchController()
        
        showAll()
    }
    
    private func configureSearchController() {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self // Objeto responsable de actualizar los resultados
        search.obscuresBackgroundDuringPresentation = false // quiero mostrar toda la tabla
        search.searchBar.placeholder = "Search Notebook..."
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
    }
    
//    private func reloadView() {
//        do {
//            dataSource = try managedContext.fetch(Notebook.fetchRequest())
//        } catch let error as NSError {
//            print(error.localizedDescription)
//            dataSource = []
//        }
//
//        populateTotalLabel()
//
//        tableView.reloadData()
//    }
    
    private func populateTotalLabel(with predicate: NSPredicate = NSPredicate(value: true)) {
        let fetchRequest = NSFetchRequest<NSNumber>(entityName: "Notebook")
        fetchRequest.resultType = .countResultType
        
        fetchRequest.predicate = predicate
        
        do {
            let countResult = try managedContext.fetch(fetchRequest)
            let count = countResult.first!.intValue
            totalLabel.text = "\(count)"
        } catch let error as NSError {
            print("Count not fetch: \(error)")
        }
    }
    
    @IBAction func addNotebook(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Nuevo Notebook", message: "Añadir un nuevo Notebook", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Guardar", style: .default) { [unowned self] action in
            guard let textField = alert.textFields?.first, let nameToSave = textField.text else { return }
            
            let notebook = Notebook(context: self.managedContext) // Crea el entity (inicializo una clase de CoreData)
            notebook.name = nameToSave
            notebook.creationDate = NSDate()
            
            do {
                try self.managedContext.save() // Guarda
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
//        return model.count
        //return dataSource.count
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
//        let notebook = model[indexPath.row]
//        let notesListVC = NoteListViewController(notebook: notebook)
//        show(notesListVC, sender: nil)
        //navigationController?.show(notesListVC, sender: nil) // Es lo mismo, pero no es necesario que exista un navC
        
        //let notebook = dataSource[indexPath.row] as! Notebook
        let notebook = fetchedResultsController.object(at: indexPath)
        //let notesListVC = NoteListViewController(notebook: notebook, managedContext: managedContext)
        
        let notesListVC = NewNotesListViewController(notebook: notebook, managedContext: managedContext)
        
        show(notesListVC, sender: nil)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections?[section]
        return sectionInfo?.name
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Eliminar Notebook
//        guard let notebookToRemove = dataSource[indexPath.row] as? Notebook, editingStyle == .delete else { return }
        
        guard editingStyle == .delete else { return }
        
        let notebookToRemove = fetchedResultsController.object(at: indexPath)
        
        managedContext.delete(notebookToRemove)
        
        do {
            try managedContext.save()
            //tableView.deleteRows(at: [indexPath], with: .automatic)
        } catch let error as NSError{
            print("Error: \(error.localizedDescription)")
        }
        
        //tableView.reloadData()
        //reloadView()
        showAll()
    }
}

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
//        let fetchRequest = NSFetchRequest<Notebook>(entityName: "Notebook")
//        fetchRequest.resultType = .managedObjectResultType
//
//        let predicate = NSPredicate(format: "name CONTAINS[c] %@", query)
//        fetchRequest.predicate = predicate
//
//        do {
//            dataSource = try managedContext.fetch(Notebook.fetchRequest())
//        } catch let error as NSError {
//            print("Could not fetch \(error.localizedDescription)")
//            dataSource = []
//        }
//
//        populateTotalLabel(with: predicate)
        
        let predicate = NSPredicate(format: "name CONTAINS[c] %@", query)
        let frc = getFetchedResultsController(with: predicate)
        setNewFetchedResultController(frc)
        
        populateTotalLabel(with: predicate)
        
    }
    
    private func showAll() {
        
//        let asyncFetchRequest = NSAsynchronousFetchRequest(fetchRequest: Notebook.fetchRequest()) { [weak self] result in
//
//            guard let notebooks =  result.finalResult else {
//                self?.dataSource = []
//                return
//            }
//            self?.dataSource = notebooks
//        }
//
//        do {
//            //dataSource = try managedContext.fetch(Notebook.fetchRequest())
//            try managedContext.execute(asyncFetchRequest)
//        } catch let error as NSError {
//            print("Could not fetch \(error.localizedDescription)")
//            dataSource = []
//        }
        
        let frc = getFetchedResultsController()
        setNewFetchedResultController(frc)

        //fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Could not fetch \(error.localizedDescription)")
        }
        
        populateTotalLabel()
    }
}

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
