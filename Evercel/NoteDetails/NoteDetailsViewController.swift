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
    func didChangeNote()
}

// MARK:- NoteDetailsViewController class
class NoteDetailsViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var tagTextField: UITextField!
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
        createTagPicker()
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
    }
    
    func setupUI() {
        imageView.layer.cornerRadius = 4.0
        imageView.clipsToBounds = true
        titleTextField.font = .systemFont(ofSize:24)
        descriptionTextView.backgroundColor = .lightBurlywood
        view.backgroundColor = .lightyellow
        navigationController?.navigationBar.barTintColor = .brown
        navigationController?.navigationBar.tintColor = .lightBurlywood
        navigationController?.navigationBar.titleTextAttributes =
            [NSAttributedString.Key.foregroundColor: UIColor.lightBurlywood]
    }
    
    private func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    private func configure() {
        switch kind {
        case .existing:
            let saveButtonItem = UIBarButtonItem(title: "Guardar", style: .plain, target: self, action: #selector(saveNote))
//                UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveNote))
//            let deleteButtonItem = UIBarButtonItem(title: "Eliminar", style: .plain, target: self, action: #selector(deleteNote))
            let deleteButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteNote))
            self.navigationItem.rightBarButtonItems = [saveButtonItem, deleteButtonItem]
        case .new:
            let saveButtonItem = UIBarButtonItem(title: "Guardar", style: .plain, target: self, action: #selector(saveNote))
            self.navigationItem.rightBarButtonItem = saveButtonItem
        }
        
        let cancelButtonItem = UIBarButtonItem(title: "Cancelar", style: .plain, target: self, action: #selector(cancel))
//            UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelButtonItem
        
        configureValues()
    }

    @objc private func saveNote() {
        switch kind {
        case .new(let notebook):
            guard isTitleNotEmpty(title: titleTextField.text) else { return }
            
            let note = Note(context: managedContext)
            let newNote = addProperties(to: note)
            newNote.creationDate = NSDate()
            newNote.lastSeenDate = NSDate()
            newNote.notebook = notebook
            newNote.tag = tagTextField.text
            
            if let notes = notebook.notes?.mutableCopy() as? NSMutableOrderedSet {
                notes.add(note)
                notebook.notes = notes
            }
            
            requestLocationPermission()
            
            if let coordinates = locationManager.location?.coordinate {
                note.latitude = coordinates.latitude
                note.longitude = coordinates.longitude
            }
            
            // Settear la relación inversa
            // El note tiene que pertenecer a los notes de ... tal, sino puede saltar un error
            if let notes = notebook.notes?.mutableCopy() as? NSMutableOrderedSet {
                notes.add(note)
                notebook.notes = notes
            }
            
            // Enviar una notificacion
            let nc = NotificationCenter.default
            let notification = Notification(name: Notification.Name(rawValue: "didAddNote"), object: self, userInfo: nil)
            // Enviar notificacion
            nc.post(notification)
            
        case .existing(let note):
            guard isTitleNotEmpty(title: titleTextField.text) else { return }
            
            let modifiedNote = addProperties(to: note)
            modifiedNote.lastSeenDate = NSDate()
        }
        do {
            try managedContext.save()
            delegate?.didChangeNote()
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func isTitleNotEmpty(title: String?) -> Bool {
        guard let title = title, title != "" else {
            
            let alertController = UIAlertController(title: "Advertencia", message: "Para poder guardar la nota correctamente debe incluir un título", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Aceptar", style: .cancel, handler: nil)
            
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true)
            
            return false
        }
        
        return true
    }
    
    @objc private func deleteNote() {
        switch kind {
        case .existing(let note):
            managedContext.delete(note)
        default:
            break
        }
        
        do {
            try managedContext.save()
            delegate?.didChangeNote()
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func cancel() {
        switch kind {
        case .existing(let note):
            let modifiedNote = note
            modifiedNote.lastSeenDate = NSDate()
        default:
            break
        }
        
        do {
            try managedContext.save()
            delegate?.didChangeNote()
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func addProperties(to note: Note) -> Note {
        note.title = titleTextField.text
        note.tag = tagTextField.text
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
        tagTextField.text = kind.note?.tag//note.tags?.joined(separator: ",")
        creationDateLabel.text = "\((kind.note?.creationDate as Date?)?.customStringLabel() ?? "Not available")"
        lastSeenDateLabel.text = "\((kind.note?.lastSeenDate as Date?)?.customStringLabel() ?? "Not available")"
        descriptionTextView.text = kind.note?.text ?? ""
        
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

// MARK: - CLLocationManagerDelegate
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

// MARK: - UIPickerView Methods
extension NoteDetailsViewController {
    
    enum Tag: Int, CaseIterable {
        case Personal, Todo, Info, Otros
    }
    
    func createTagPicker() {
        let tagPicker = UIPickerView()
        tagPicker.backgroundColor = .lightyellow
        tagPicker.delegate = self
        
        tagTextField.inputView = tagPicker
    }
}

// MARK: - UIPickerViewDelegate and UIPickerViewDataSource
extension NoteDetailsViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Tag.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(Tag.init(rawValue: row)!)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        tagTextField.text = "\(Tag.init(rawValue: row)!)"
    }
}
