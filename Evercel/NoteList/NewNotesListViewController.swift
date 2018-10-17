//
//  NewNotesListViewController.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 11/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//

import UIKit
import CoreData

class NewNotesListViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Properties
    let notebook: Notebook
    let coreDataStack: CoreDataStack
    var notes: [Note] {
        didSet {
            collectionView.reloadData()
        }
    }
    let transition = Animator()
    
    enum Constants {
        static let columns : CGFloat = 2
    }
    
    // MARK: - Initialization
    init(notebook: Notebook, coreDataStack: CoreDataStack) {
        self.notebook = notebook
        self.notes = (notebook.notes?.array as? [Note]) ?? []
        self.coreDataStack = coreDataStack
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lyfe Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        let nib = UINib(nibName: "NotesListCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "NotesListCollectionViewCell")
        
        let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNote))
        let exportButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(exportCsv))
        self.navigationItem.rightBarButtonItems = [addButtonItem, exportButtonItem]
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
        title = "Notas"
        
        self.view.backgroundColor = .white
        
        collectionView.backgroundColor = .gainsboro
        
        collectionView.dataSource = self
        collectionView.delegate = self
    }

}

// MARK: - UICollectionViewDataSource
extension NewNotesListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return notes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NotesListCollectionViewCell", for: indexPath) as! NotesListCollectionViewCell
        cell.configure(with: notes[indexPath.row])
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension NewNotesListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let note = notes[indexPath.row]
        let detailVC = NoteDetailsViewController(kind: .existing(note: note), managedContext: coreDataStack.managedContext)
        detailVC.delegate = self
        //show(detailVC, sender: nil)
        
        // Custom animation
        let navVC = UINavigationController(rootViewController: detailVC)
        navVC.transitioningDelegate = self
        present(navVC, animated: true, completion: nil)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension NewNotesListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 150)
    }
}

// MARK: - NoteDetailsViewControllerProtocol implementation
extension NewNotesListViewController: NoteDetailsViewControllerDelegate {
    func didSaveNote() {
        notes = (notebook.notes?.array as? [Note]) ?? []
    }
}

// MARK: - Custom Animation - UIViewControllerTransitioningDelegate
extension NewNotesListViewController : UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let indexPath = (collectionView.indexPathsForSelectedItems?.first!)!
        let cell = collectionView.cellForItem(at: indexPath)
        transition.originFrame = cell!.superview!.convert(cell!.frame, to: nil)
        transition.presenting = true
        
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}
