//
//  ViewController.swift
//  Project10
//
//  Created by Yulian Gyuroff on 11.10.23.
//
import LocalAuthentication
import UIKit

class ViewController: UICollectionViewController ,
                      UIImagePickerControllerDelegate,
                      UINavigationControllerDelegate {
    
    var people = [Person]()
    var unlockedPeople = [Person]()
    var unlockButton = UIBarButtonItem()
    var lockButton = UIBarButtonItem()
    var unlockedPictures = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewPerson))
        
        unlockButton = UIBarButtonItem(title: "Unlock", style: .plain, target: self, action: #selector(unlockPictures))
        lockButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(lockPictures))
        
        navigationItem.rightBarButtonItem = unlockButton
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return unlockedPeople.count
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Person", for: indexPath) as? PersonCell else { fatalError("Unable to deque th PersonCell.")}
        
        let person = unlockedPeople[indexPath.item]
        cell.name.text = person.name
        let path = getDocumentsDirectory().appendingPathComponent(person.image)
        cell.imageView.image = UIImage(contentsOfFile: path.path)
        cell.imageView.layer.borderColor = UIColor(white: 0, alpha: 0.3).cgColor
        cell.imageView.layer.borderWidth = 2
        cell.imageView.layer.cornerRadius = 3
        cell.layer.cornerRadius = 7
        
        return cell
    }
    
    @objc func addNewPerson() {
        guard unlockedPictures else {
            let ac = UIAlertController(title: "Not allowed", message: "Unlock first", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(ac, animated: true)
            return
        }
                
        let acChoice = UIAlertController(title: "Select image source", message: nil, preferredStyle: .alert)
        acChoice.addAction(UIAlertAction(title: "Library", style: .default, handler: submitForLibrary))
        acChoice.addAction(UIAlertAction(title: "Camera", style: .default, handler: submitForCamera))
        present(acChoice, animated: true)
    }
    @objc func submitForLibrary(alertAction: UIAlertAction){
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    @objc func submitForCamera(alertAction: UIAlertAction){
        if UIImagePickerController.isSourceTypeAvailable(.camera) == true{
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.allowsEditing = true
            picker.delegate = self
            present(picker, animated: true)
        }else{
            let ac = UIAlertController(title: "Camera", message: "Camera not found.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Cancel", style: .default))
            present(ac, animated: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imagePath)
        }
        let person = Person(name: "Unknown", image: imageName)
        people.append(person)
        if unlockedPictures {
            unlockedPeople = people
        }else{
            unlockedPeople.removeAll()
        }
        collectionView.reloadData()
        
        dismiss(animated: true)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let person = people[indexPath.item]
        
        let ac = UIAlertController(title: "Rename person", message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.addAction(UIAlertAction(title: "OK", style: .default) {
            [weak self,weak ac] _ in
            guard let newName = ac?.textFields?[0].text else { return }
            person.name = newName
            self?.unlockedPeople = self?.people ?? [Person]()
            self?.collectionView.reloadData()
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        //present(ac, animated: true)
        
        let acFirst = UIAlertController(title: "Choose action", message: nil, preferredStyle: .alert)
        acFirst.addAction(UIAlertAction(title: "Rename", style: .default){
            [weak self] _ in
            self?.present(ac, animated: true)
        } )
        
        acFirst.addAction(UIAlertAction(title: "Delete", style: .default){
            [weak self] _ in
            self?.people.remove(at: indexPath.item)
            self?.unlockedPeople = self?.people ?? [Person]()
            self?.collectionView.reloadData()
        })
        
        present(acFirst, animated: true)
    }
    
    @objc func unlockPictures() {
        
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self?.unlockedPeople = self?.people ?? [Person]()
                        self?.unlockedPictures = true
                        self?.collectionView.reloadData()
                    } else {
                        //error
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified, please try again", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(ac, animated: true)
                    }
                }
            }
            
        } else {
            // no biometry
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
        
        navigationItem.rightBarButtonItem = lockButton
    }
    
    @objc func lockPictures() {
        unlockedPeople.removeAll()
        unlockedPictures = false
        navigationItem.rightBarButtonItem = unlockButton
        collectionView.reloadData()
    }
    
}

