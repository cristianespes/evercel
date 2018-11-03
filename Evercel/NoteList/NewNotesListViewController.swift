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
    
    let transition = Animator()
    
    enum Constants {
        static let columns : CGFloat = 2
    }
    
    private var fetchedResultsController: NSFetchedResultsController<Note>!
    
    private func getFetchedResultsController(with predicate: NSPredicate = NSPredicate(value: true)) -> NSFetchedResultsController<Note> {

        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        
        fetchRequest.fetchBatchSize = 50
        
        let predicateNotebook = NSPredicate(format: "notebook == %@", notebook) // Todas las notas que pertecenen a ese notebook
        
        let predicates = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [predicateNotebook, predicate])
        
        fetchRequest.predicate = predicates
        
        let sort = NSSortDescriptor(key: #keyPath(Note.creationDate), ascending: true)
        fetchRequest.sortDescriptors = [sort]
        
        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: coreDataStack.managedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
    }
    
    private func setNewFetchedResultController(_ newFrc: NSFetchedResultsController<Note>) {
        let oldFrc = fetchedResultsController
        if (newFrc != oldFrc) {
            fetchedResultsController = newFrc
            do {
                try fetchedResultsController.performFetch()
            } catch let error as NSError {
                print("Could not fetch \(error.localizedDescription)")
            }
            collectionView.reloadData()
        }
    }
    
    func showFilteredResults(with query: String) {
        let predicate = NSPredicate(format: "title CONTAINS[c] %@", query)
        let frc = getFetchedResultsController(with: predicate)
        setNewFetchedResultController(frc)
    }
    
    
    // MARK: - Initialization
    init(notebook: Notebook, coreDataStack: CoreDataStack) {
        self.notebook = notebook
        self.coreDataStack = coreDataStack
        
        super.init(nibName: nil, bundle: nil)
        
        title = "Listado"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        // Baja en la notificación
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }
    
    // MARK: - Lyfe Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        showAll()
        
        let nib = UINib(nibName: "NotesListCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "NotesListCollectionViewCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Nos damos de alta en las notificaciones
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(notesDidChange), name: Notification.Name(rawValue: "didAddNote"), object: nil)
    }
    
    // MARK: - Notifications
    @objc func notesDidChange(notification: Notification) {
        // Actualizar el modelo
        showAll()
        // Sincronizar las vistas
        collectionView.reloadData()
    }
    
    func showAll() {
        let frc = getFetchedResultsController()
        setNewFetchedResultController(frc)
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Could not fetch \(error.localizedDescription)")
        }
    }
    
    func setupUI() {
        self.view.backgroundColor = .white
        
        collectionView.backgroundColor = .lightyellow
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
    }

}

// MARK: - UICollectionViewDataSource
extension NewNotesListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultsController.sections?[section] else { return 0 }

        return sectionInfo.numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let note = fetchedResultsController.object(at: indexPath)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NotesListCollectionViewCell", for: indexPath) as! NotesListCollectionViewCell
        cell.configure(with: note)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension NewNotesListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let note = fetchedResultsController.object(at: indexPath)
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
    func didChangeNote() {
        showAll()
        collectionView.reloadData()
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
