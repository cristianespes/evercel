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
    
    var dataSource: [NSManagedObject] = []
    
    override func viewDidLoad() {
//        model = deprecated_Notebook.dummyNotebookModel
        
//        navigationController?.navigationBar.prefersLargeTitles = true
//        navigationController?.navigationItem.largeTitleDisplayMode = .always
        
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        reloadView()
    }
    
    private func reloadView() {
        do {
            dataSource = try managedContext.fetch(Notebook.fetchRequest())
        } catch let error as NSError {
            print(error.localizedDescription)
            dataSource = []
        }
        
        populateTotalLabel()
        
        tableView.reloadData()
    }
    
    private func populateTotalLabel() {
        let fetchRequest = NSFetchRequest<NSNumber>(entityName: "Notebook")
        fetchRequest.resultType = .countResultType
        
        let predicate = NSPredicate(value: true)
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
            self.reloadView()
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return model.count
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotebookListCell", for: indexPath) as! NotebookListCell
        
//        cell.configure(with: model[indexPath.row])
        let notebook = dataSource[indexPath.row] as! Notebook
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
        
        let notebook = dataSource[indexPath.row] as! Notebook
        let notesListVC = NoteListViewController(notebook: notebook, managedContext: managedContext)
        show(notesListVC, sender: nil)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Eliminar Notebook
        guard let notebookToRemove = dataSource[indexPath.row] as? Notebook, editingStyle == .delete else { return }
        
        managedContext.delete(notebookToRemove)
        
        do {
            try managedContext.save()
            //tableView.deleteRows(at: [indexPath], with: .automatic)
        } catch let error as NSError{
            print("Error: \(error.localizedDescription)")
        }
        
        //tableView.reloadData()
        reloadView()
    }
}
