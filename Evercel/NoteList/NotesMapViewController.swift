//
//  NotesMapViewController.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 20/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//

import UIKit
import MapKit

class NotesMapViewController: UIViewController {
    
    // MARK: - Properties
    let notebook: Notebook
    let coreDataStack: CoreDataStack
    var notes: [Note]
    var locationsOfNote: [LocationOfNote] = []
    let locationManager = CLLocationManager()
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Initialization
    init(notebook: Notebook, coreDataStack: CoreDataStack) {
        self.notebook = notebook
        self.coreDataStack = coreDataStack
        self.notes = (notebook.notes?.array as? [Note]) ?? []
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Lyfe Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        super.viewDidLoad()
        let myHome = CLLocationCoordinate2D(latitude: 41.646777, longitude: -0.866051)
        let regionRadius: CLLocationDistance = 1000
        let region = MKCoordinateRegion(center: myHome, latitudinalMeters: regionRadius, longitudinalMeters: 1000)
        
        mapView.setRegion(region, animated: true)
        
        setupUI()
    }
    
    func setupUI() {
        title = "Mapa de notas"
        
        self.view.backgroundColor = .white
        
        mapView.delegate = self
    }
    
    private func loadLocationsOfNote() {
        
        notes.forEach { note in
            let noteLocalize = LocationOfNote(title: note.title!, date: ((note.creationDate as Date?)?.customStringLabel())!, location: CLLocationCoordinate2D(latitude: note.latitude, longitude: note.longitude))
            
            locationsOfNote.append(noteLocalize)
        }
        
//        let myHome = LocationOfNote(title: "My Home", date: "Para poder dormir", location: CLLocationCoordinate2D(latitude: 41.646777, longitude: -0.866051))
//        locationsOfNote.append(myHome)
    }
    
    /*func configure(with item: Note) {
        //backgroundColor = .burlywood
        titleLabel.text = item.title
        if let data = item.image as Data? {
            imageView.image = UIImage(data: data)
            titleLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
            creationDateLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
        } else {
            imageView.image = UIImage(named: "120x180")
        }
        imageView.contentMode = .scaleAspectFill
        creationDateLabel.text = (item.creationDate as Date?)?.customStringLabel()
    }*/

}

// MARK: - MKMapViewDelegate
extension NotesMapViewController: MKMapViewDelegate {
    
    // Para poder escuchar cuando comienza a pintar el mapa
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        print("rendering")
    }
    
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        // Cargar puntos de interes
        loadLocationsOfNote()
        mapView.addAnnotations(locationsOfNote)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        var annotacionView = mapView.dequeueReusableAnnotationView(withIdentifier: "locationOfNote") as? MKMarkerAnnotationView
        
        if annotacionView == nil {
            annotacionView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "locationOfNote")
        } else {
            annotacionView?.annotation = annotation
        }
        
        annotacionView?.markerTintColor = .green
        annotacionView?.titleVisibility = .visible
        annotacionView?.subtitleVisibility = .adaptive
        
        return annotacionView
    }
    
}
