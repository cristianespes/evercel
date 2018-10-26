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
        
        title = "Listado"
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
    func didChangeNote() {
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
