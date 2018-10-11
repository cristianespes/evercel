//
//  NoteListViewController.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 08/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//

import UIKit

class NoteListViewController: UIViewController {
    
    lazy var tableView: UITableView = {
        let tableview = UITableView(frame: .zero, style: .plain)
        tableview.translatesAutoresizingMaskIntoConstraints = false
        return tableview
    }()
    
    let notebook: Notebook //deprecated_Notebook
    
//    var notes: [deprecated_Note] = [] {
//        didSet {
//            tableView.reloadData()
//        }
//    }
    
    var notes: [Note] {
        guard let notes = notebook.notes?.array else {return []}
        
        return notes as! [Note]
    }
    
    //init(notebook: deprecated_Notebook) {
    init(notebook: Notebook) {
        self.notebook = notebook
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        title = "Notas de: \(notebook.name)"
        title = "Notas"
        
//        notes = notebook.notes
        navigationController?.navigationBar.isTranslucent = true
        navigationItem.largeTitleDisplayMode = .never
        
        let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add
            , target: self, action: #selector(addNote))
        navigationItem.rightBarButtonItem = addButtonItem
        
        setupTableView()
    }
    
    @objc private func addNote() {
        let newNoteVC = NoteDetailsViewController(kind: .new)
        let navVC = UINavigationController(rootViewController: newNoteVC)
        present(navVC, animated: true, completion: nil)
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
}

extension NoteListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = notes[indexPath.row].title
        
        return cell
    }
}

extension NoteListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let note = notes[indexPath.row]
        //let detailVC = NoteDetailsViewController(note: notes[indexPath.row])
        let detailVC = NoteDetailsViewController(kind: .existing(note))
        show(detailVC, sender: nil)
    }
}
