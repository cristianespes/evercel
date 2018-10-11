//
//  NoteDetailsViewController.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 09/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//

import UIKit
import CoreData

protocol NoteDetailsViewControllerDelegate: class {
    func didSaveNote()
}

class NoteDetailsViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    @IBOutlet weak var lastSeenDateLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    // MARK: - Properties
    //let note: Note
    
    enum Kind {
        case new(notebook: Notebook)
        case existing(note: Note)
    }
    
    let managedContext : NSManagedObjectContext
    
    let kind: Kind
    
    weak var delegate: NoteDetailsViewControllerDelegate?
    
    // MARK: - Initialization
    init(kind: Kind, managedContext: NSManagedObjectContext) {
        //self.note = note
        self.kind = kind
        self.managedContext = managedContext
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure(with: kind)
    }
    
    private func configure(with kind: Kind) {
        switch kind {
        case .new:
            let saveButtonItem = UIBarButtonItem(barButtonSystemItem: .save
                , target: self, action: #selector(saveNote))
            self.navigationItem.rightBarButtonItem = saveButtonItem
            let cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
            navigationItem.leftBarButtonItem = cancelButtonItem
            configureValues()
        case .existing:
            configureValues()
        }
    }

    @objc private func saveNote() {
        switch kind {
        case .new(let notebook):
            let note = Note(context: managedContext)
            note.title = titleTextField.text
            note.text = descriptionTextView.text
            note.lastSeenDate = NSDate()
            
            // Settear la relación inversa
            // El note tiene que pertenecer a los notes de ... tal, sino puede saltar un error
            if let notes = notebook.notes?.mutableCopy() as? NSMutableOrderedSet {
                notes.add(note)
                notebook.notes = notes
            }
            
            do {
                try managedContext.save()
                delegate?.didSaveNote()
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
            }
            
            dismiss(animated: true, completion: nil)
            
        case .existing(let note):
            note.title = titleTextField.text
            note.text = descriptionTextView.text
            note.lastSeenDate = NSDate()
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
            }
            
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    private func configureValues() {
        title = kind.title
        titleTextField.text = kind.note?.title
        //tagsLabel.text = note.tags?.joined(separator: ",")
        creationDateLabel.text = "Creado: \((kind.note?.creationDate as Date?)?.customStringLabel() ?? "ND")"
        lastSeenDateLabel.text = "Visto: \((kind.note?.lastSeenDate as Date?)?.customStringLabel() ?? "ND")"
        descriptionTextView.text = kind.note?.text ?? "Ingrese texto..."
    }

}

private extension NoteDetailsViewController.Kind {
    var note: Note? {
        guard case let .existing(note) = self else { return nil }
        return note
    }
    
    var title: String {
        switch self {
        case .existing:
            return "Detalle"
        case .new:
            return "Nueva Nota"
        }
    }
}
