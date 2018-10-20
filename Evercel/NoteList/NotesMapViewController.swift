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
        
        title = "Mapa"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Lyfe Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        super.viewDidLoad()
        
        setupUI()
        
        let myHome = CLLocationCoordinate2D(latitude: 37.78583526611328, longitude: -122.40641784667969)
        //let myHome = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        //let myHome = CLLocationCoordinate2D(latitude: 41.646777, longitude: -0.866051)
        let regionRadius: CLLocationDistance = 1000
        let region = MKCoordinateRegion(center: myHome, latitudinalMeters: regionRadius, longitudinalMeters: 1000)
        
        mapView.setRegion(region, animated: true)
    }
    
    func setupUI() {
        self.view.backgroundColor = .white
        
        mapView.delegate = self
    }
    
    private func loadLocationsOfNote() {
        
        notes.forEach { note in
            let noteLocalize = LocationOfNote(title: note.title!, date: ((note.creationDate as Date?)?.customStringLabel())!, location: CLLocationCoordinate2D(latitude: note.latitude, longitude: note.longitude))
            
            //print("latitude: \(note.latitude), longitude: \(note.longitude)")
            
            locationsOfNote.append(noteLocalize)
        }
        
        let noteLocalize1 = LocationOfNote(title: "Prueba1", date: "Fecha1", location: CLLocationCoordinate2D(latitude: 37.785021, longitude: -122.402974))
        locationsOfNote.append(noteLocalize1)
        
        let noteLocalize2 = LocationOfNote(title: "Prueba2", date: "Fecha2", location: CLLocationCoordinate2D(latitude: 37.782054, longitude: -122.40527))
        locationsOfNote.append(noteLocalize2)
        
        let noteLocalize3 = LocationOfNote(title: "Prueba3", date: "Fecha3", location: CLLocationCoordinate2D(latitude: 37.78107, longitude: -122.410216))
        locationsOfNote.append(noteLocalize3)
        
//        let myHome = LocationOfNote(title: "My Home", date: "Para poder dormir", location: CLLocationCoordinate2D(latitude: 41.646777, longitude: -0.866051))
//        locationsOfNote.append(myHome)
    }

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
    
//    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//        print("Pulsado chincheta: \(view.annotation?.title) ")
//    }
    
}
