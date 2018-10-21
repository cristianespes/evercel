//
//  PresentNotesVC.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 20/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//

import UIKit
import CoreData

class PresentNotesVC: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var contentView: UIView!
    
    // MARK: - Properties
    let notebook: Notebook
    let coreDataStack: CoreDataStack
    var currentViewController: UIViewController?
    lazy var notesListViewController: UIViewController = {
        let notesListVC = NewNotesListViewController(notebook: notebook, coreDataStack: coreDataStack)
        return notesListVC
    }()
    lazy var notesMapViewController: UIViewController = {
        let notesMapVC = NotesMapViewController(notebook: notebook, coreDataStack: coreDataStack)
        return notesMapVC
    }()
    
    
    // MARK: - Initialization
    init(notebook: Notebook, coreDataStack: CoreDataStack) {
        self.notebook = notebook
        self.coreDataStack = coreDataStack
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lyfe Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //navigationItem.title = "Notas"
        title = "Notas"
        
        navigationController?.navigationBar.isTranslucent = false

        setupUI()
        displayCurrentTab(0)
        
        let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNote))
        let exportButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(exportCsv))
        navigationItem.rightBarButtonItems = [addButtonItem, exportButtonItem]
    }
    
    // MARK: - Helper methods
    @objc private func addNote() {
        let newNoteVC = NoteDetailsViewController(kind: .new(notebook: notebook), managedContext: coreDataStack.managedContext)
        newNoteVC.delegate = self
        let navVC = UINavigationController(rootViewController: newNoteVC)
        self.present(navVC, animated: true, completion: nil)
    }
    
    @objc private func exportCsv() {
        coreDataStack.storeContainer.performBackgroundTask { [unowned self] (context) in
            var results: [Note] = []
            
            do {
                // Recogemos la informaión
                results = try self.coreDataStack.managedContext.fetch(self.notesFetchRequest(from: self.notebook))
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
            }
            
            // Exportamos la información
            let exportPath = NSTemporaryDirectory() + "export.csv"
            let exportURL = URL(fileURLWithPath: exportPath)
            FileManager.default.createFile(atPath: exportPath, contents: Data(), attributes: nil)
            
            // Almacenamos la informaicón
            let fileHandle: FileHandle?
            do {
                fileHandle = try FileHandle(forWritingTo: exportURL)
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
                fileHandle = nil
            }
            
            if let fileHandle = fileHandle {
                for note in results {
                    fileHandle.seekToEndOfFile() // Añadir al final del archivo
                    guard  let csvData = note.csv().data(using: .utf8, allowLossyConversion: false) else { return }
                    fileHandle.write(csvData)
                }
                
                fileHandle.closeFile()
                
                // Avisamos al usuario cuando finaliza
                DispatchQueue.main.async { [weak self] in
                    self?.showExportFinishedAlert(exportPath)
                }
                
            } else {
                print("No ha sido posible exportar los datos")
            }
        }
    }
    
    private func showExportFinishedAlert(_ exportPath: String) {
        let message = "El archivo CSV se encuentra en \(exportPath)"
        let alertController = UIAlertController(title: "Exportación finalizada", message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Aceptar", style: .default)
        alertController.addAction(dismissAction)
        
        present(alertController, animated: true)
    }
    
    private func notesFetchRequest(from notebook: Notebook) -> NSFetchRequest<Note> {
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        fetchRequest.fetchBatchSize = 50
        fetchRequest.predicate = NSPredicate(format: "notebook == %@", notebook) // Todas las notas que pertecenen a ese notebook
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        return fetchRequest
    }
    
    func setupUI() {
        segmentedControl.setTitle("Listado", forSegmentAt: 0)
        segmentedControl.setTitle("Mapas", forSegmentAt: 1)
//        segmentedControl.selectedSegmentIndex = 0
        
        //view.backgroundColor = .burlywood
        segmentedControl.backgroundColor = .white
    }

    
    @IBAction func switchViews(_ sender: UISegmentedControl) {
        changeViewsToShow(sender.selectedSegmentIndex)
    }
    
    func displayCurrentTab(_ index: Int){
        if let vc = viewControllerForSelectedSegmentIndex(index) {
            
            self.addChild(vc)
            vc.didMove(toParent: self)
            
            vc.view.frame = self.contentView.bounds
            self.contentView.addSubview(vc.view)
            self.currentViewController = vc
        }
    }
    
    func changeViewsToShow(_ index: Int) {
        self.currentViewController?.view.removeFromSuperview()
        self.currentViewController?.removeFromParent()
        
        displayCurrentTab(index)
    }
    
    func viewControllerForSelectedSegmentIndex(_ index: Int) -> UIViewController? {
        var vc: UIViewController?
        switch index {
        case 0 :
            vc = notesListViewController
        case 1 :
            vc = notesMapViewController
        default:
            return nil
        }
        
        return vc
    }

}

// MARK: - NoteDetailsViewControllerProtocol implementation
extension PresentNotesVC: NoteDetailsViewControllerDelegate {
    func didSaveNote() {
        notesListViewController = NewNotesListViewController(notebook: notebook, coreDataStack: coreDataStack)
        notesMapViewController = NotesMapViewController(notebook: notebook, coreDataStack: coreDataStack)
        
        changeViewsToShow(segmentedControl.selectedSegmentIndex)
    }
}
