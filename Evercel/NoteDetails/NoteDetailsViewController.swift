//
//  NoteDetailsViewController.swift
//  Evercel
//
//  Created by CRISTIAN ESPES on 09/10/2018.
//  Copyright © 2018 Cristian Espes. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

// MARK: - NoteDetailsViewControllerProtocol
protocol NoteDetailsViewControllerDelegate: class {
    func didSaveNote()
}

// MARK:- NoteDetailsViewController class
class NoteDetailsViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    @IBOutlet weak var lastSeenDateLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    // MARK: - Properties
    enum Kind {
        case new(notebook: Notebook)
        case existing(note: Note)
    }
    
    let managedContext : NSManagedObjectContext
    let kind: Kind
    let locationManager = CLLocationManager()
    weak var delegate: NoteDetailsViewControllerDelegate?
    
    
    // MARK: - Initialization
    init(kind: Kind, managedContext: NSManagedObjectContext) {
        self.kind = kind
        self.managedContext = managedContext
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupLocation()
        configure()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
    }
    
    func setupUI() {
        imageView.layer.cornerRadius = 4.0
        imageView.clipsToBounds = true
        titleTextField.font = .systemFont(ofSize:24)
        descriptionTextView.backgroundColor = .lightBurlywood
    }
    
    private func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    private func configure() {
        let saveButtonItem = UIBarButtonItem(barButtonSystemItem: .save
            , target: self, action: #selector(saveNote))
        self.navigationItem.rightBarButtonItem = saveButtonItem
        let cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelButtonItem
        
        configureValues()
    }

    @objc private func saveNote() {
        
        func addProperties(to note: Note) -> Note {
            note.title = titleTextField.text
            note.tag = tagsLabel.text
            note.text = descriptionTextView.text
            
            let imageData: NSData?
            if let image = imageView.image,
                let data = image.pngData() {
                imageData = NSData(data: data)
            } else {
                imageData = nil
            }
            note.image = imageData
            
            return note
        }
        
        switch kind {
        case .new(let notebook):
            let note = Note(context: managedContext)
            let modifiedNote = addProperties(to: note)
            modifiedNote.creationDate = NSDate()
            modifiedNote.notebook = notebook
            modifiedNote.tag = "Etiqueta aquí"//tagsLabel.text
            
            if let notes = notebook.notes?.mutableCopy() as? NSMutableOrderedSet {
                notes.add(note)
                notebook.notes = notes
            }
            
            requestLocationPermission()
//            note.latitude = Float(locationManager.location?.coordinate.latitude ?? 0)
//            note.longitude = Float(locationManager.location?.coordinate.longitude ?? 0)
            if let coordinates = locationManager.location?.coordinate {
                note.latitude = coordinates.latitude
                note.longitude = coordinates.longitude
            }
            print("latitude: \(note.latitude) / longitude: \(note.longitude)")
            
            // Settear la relación inversa
            // El note tiene que pertenecer a los notes de ... tal, sino puede saltar un error
            if let notes = notebook.notes?.mutableCopy() as? NSMutableOrderedSet {
                notes.add(note)
                notebook.notes = notes
            }
        case .existing(let note):
            let modifiedNote = addProperties(to: note)
            modifiedNote.lastSeenDate = NSDate()
        }
        
        do {
            try managedContext.save()
            delegate?.didSaveNote()
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func pickImage(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }
    
    private func showPhotoMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default, handler: { _ in self.takePhotoWithCamera() })
        let chooseFromLibrary = UIAlertAction(title: "Choose From Library", style: .default, handler: { _ in self.choosePhotoFromLibrary() })
        
        alertController.addAction(cancelAction)
        alertController.addAction(takePhotoAction)
        alertController.addAction(chooseFromLibrary)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func configureValues() {
        title = kind.title
        titleTextField.text = kind.note?.title
        tagsLabel.text = kind.note?.tag//note.tags?.joined(separator: ",")
        creationDateLabel.text = "\((kind.note?.creationDate as Date?)?.customStringLabel() ?? "Not available")"
        lastSeenDateLabel.text = "\((kind.note?.lastSeenDate as Date?)?.customStringLabel() ?? "Not available")"
        descriptionTextView.text = kind.note?.text ?? "Ingrese texto..."
        
        guard let imageData = kind.note?.image as Data? else {
            // TODO: CAMBIAR PARA MOSTRAR PLACE HOLDER
            imageView.image = UIImage(named: "120x180")
            return
        }
        imageView.image = UIImage(data: imageData)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

}

// MARK: - NoteDetailsViewController.Kind extension
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

// MARK: - UIImagePickerControllerDelegate & related methods
extension NoteDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }
    
    func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        // capturo la imagen editada
        let rawImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage
        
        // calculo el tamaño de la imagen a mostrar
        let imageSize = CGSize(width: self.imageView.bounds.width * UIScreen.main.scale, height: self.imageView.bounds.height * UIScreen.main.scale)
        
        DispatchQueue.global(qos: .default).async {
            let image = rawImage?.resizedImageWithContentMode(.scaleAspectFill, bounds: imageSize, interpolationQuality: .high)
            
            DispatchQueue.main.async {
                if let image = image {
                    self.imageView.contentMode = .scaleAspectFill
                    self.imageView.clipsToBounds = true
                    self.imageView.image = image
                }
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
}

extension NoteDetailsViewController: CLLocationManagerDelegate {
    
    func requestLocationPermission() {
        // Comprobar si está disponible el servicio de Localización
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        /*if let location = locations.last {
            print("latitude: \(location.coordinate.latitude), longitude: \(location.coordinate.longitude)")
            switch kind {
            case .new:
                self.kind.note?.latitude = Float(location.coordinate.latitude)
                self.kind.note?.longitude = Float(location.coordinate.longitude)
            default:
                break
            }
        }*/
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("No fue posible obtener la ubicación del usuario")
    }
}
