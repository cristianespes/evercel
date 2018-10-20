//
//  PresentNotesVC.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 20/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//

import UIKit

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

        setupUI()
        segmentedControl.selectedSegmentIndex = 0
        
        displayCurrentTab(0)
    }
    
    func setupUI() {
        segmentedControl.setTitle("Listado", forSegmentAt: 0)
        segmentedControl.setTitle("Mapas", forSegmentAt: 1)
        
        segmentedControl.selectedSegmentIndex = 0
    }

    
    @IBAction func switchViews(_ sender: UISegmentedControl) {
        self.currentViewController?.view.removeFromSuperview()
        self.currentViewController?.removeFromParent()
        
        displayCurrentTab(sender.selectedSegmentIndex)
        
    }
    
    func displayCurrentTab(_ tabIndex: Int){
        if let vc = viewControllerForSelectedSegmentIndex(tabIndex) {
            
            self.addChild(vc)
            vc.didMove(toParent: self)
            
            vc.view.frame = self.contentView.bounds
            self.contentView.addSubview(vc.view)
            self.currentViewController = vc
        }
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
