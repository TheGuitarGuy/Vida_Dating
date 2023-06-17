//
//  PhotoUploadView.swift
//  Vida Dating
//
//  Created by Kennion Gubler on 4/19/23.
//
import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import SDWebImageSwiftUI // add this import statement

struct PhotoUploadView: View {
    @State var selectedImages: [UIImage?] = [nil, nil, nil, nil, nil, nil]
    @State private var coordinator: Coordinator?
    @State private var saveButtonTapped = false
    @State private var userID: String? = Auth.auth().currentUser?.uid
    @State private var isLoadingImage = false
    @State private var userProfileImageURL: URL? = nil
    @State private var userProfileImageURLs: [URL?] = [nil, nil, nil, nil, nil, nil]
    @State private var updatedImages: [UIImage?] = []
    @State private var updatedImageIndices: [Int] = []
    
    let vidaPink = Color(red: 231/255, green: 83/255, blue: 136/255)
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(0..<3) { index in
                    imageView(forIndex: index)
                }
            }
            HStack(spacing: 10) {
                ForEach(3..<6) { index in
                    imageView(forIndex: index)
                }
            }
            Button(action: {
                saveButtonTapped = true
                saveImagesToFirebase()
            }) {
                Text("Save")
            }
        }
        .onAppear {
            loadImageURLsFromFirestore()
        }
    }

    // Define a function to return an optional image view
    func imageView(forIndex index: Int) -> some View {
        if let selectedImage = selectedImages.indices.contains(index) ? selectedImages[index] : nil {
            return AnyView(RectangleView(image: selectedImage, onTap: { index in
                presentImagePicker(index: index)
            }, index: index)
                .frame(width: 100, height: 100)
                .onTapGesture {
                    presentImagePicker(index: index)
                })
        } else if userProfileImageURLs.indices.contains(index) {
            return AnyView(AsyncImage(url: userProfileImageURLs[index]) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RectangleView(onTap: { index in
                    presentImagePicker(index: index)
                }, index: index)
            }
            .frame(width: 100, height: 100)
            .onTapGesture {
                presentImagePicker(index: index)
            })
        } else {
            // Return an empty view if both the selected images and user profile image URLs don't contain an image for the current index
            return AnyView(Color.clear.frame(width: 100, height: 100))
        }
    }


    private func saveImagesToFirebase() {
        if saveButtonTapped {
            let storageRef = Storage.storage().reference()
            let user = Auth.auth().currentUser
            let userID = user?.uid ?? ""
            
            var downloadURLs: [String] = []
            
            let group = DispatchGroup() // create a dispatch group to wait for all uploads to finish
            
            for (index, image) in selectedImages.enumerated() {
                if let imageData = image?.jpegData(compressionQuality: 0.5) {
                    let imageName = "image\(index).jpg"
                    let imageRef = storageRef.child("users/\(userID)/\(imageName)")
                    
                    group.enter() // enter the dispatch group before starting the upload task
                    
                    let uploadTask = imageRef.putData(imageData, metadata: nil) { metadata, error in
                        guard let metadata = metadata else {
                            print("Error uploading image: \(error?.localizedDescription ?? "Unknown error")")
                            group.leave() // leave the dispatch group if the upload task fails
                            return
                        }
                        
                        imageRef.downloadURL { url, error in
                            guard let downloadURL = url else {
                                print("Error retrieving download URL: \(error?.localizedDescription ?? "Unknown error")")
                                group.leave() // leave the dispatch group if getting the download URL fails
                                return
                            }
                            
                            downloadURLs.append(downloadURL.absoluteString)
                            group.leave() // leave the dispatch group after getting the download URL
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                // all upload tasks have finished
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(userID)
                userRef.updateData([
                    "photoURLs": downloadURLs
                ]) { error in
                    if let error = error {
                        print("Error updating Firestore document: \(error.localizedDescription)")
                    }
                }
                let alert = UIAlertController(title: "Photos Saved!!", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
            }
            
            saveButtonTapped = false
        }
    }






    func loadImageURLsFromFirestore() {
        guard let userID = userID else {
            print("No user is signed in.")
            return
        }
        isLoadingImage = true
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { document, error in
            self.isLoadingImage = false
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
            } else if let document = document, document.exists {
                if let photoURLs = document.data()?["photoURLs"] as? [String] {
                    for (index, photoURL) in photoURLs.enumerated() {
                        if let url = URL(string: photoURL) {
                            self.userProfileImageURLs[index] = url
                        } else {
                            print("Invalid photo URL for current user.")
                        }
                    }
                } else {
                    print("No photoURLs found for current user.")
                }
            } else {
                print("Current user document not found.")
            }
        }
    }
    
    private func presentImagePicker(index: Int) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let coordinator = Coordinator(parent: self, index: index)
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = coordinator
        picker.view.tag = index
        self.coordinator = coordinator
        
        // Find the current view controller to present the picker from
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(picker, animated: true)
        }
    }
    
    private func updateSelectedImage(image: UIImage, index: Int) {
        selectedImages[index] = image
    }
    struct ImageView: View {
        let url: URL?
        init(url: URL?) {
            self.url = url
        }

        var body: some View {
            if let url = url, let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
            }
        }
    }
    
    private struct RectangleView: View {
        var image: UIImage?
        let onTap: (Int) -> Void
        let index: Int
        
        var body: some View {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100) // add frame modifier to keep image size fixed
                        .cornerRadius(10)
                } else {
                    Rectangle()
                        .foregroundColor(.vidaPink)
                        .cornerRadius(10)
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 30))
                }
            }
            .onTapGesture {
                onTap(index)
            }
            .frame(width: 100, height: 100)
        }
    }


    private class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoUploadView
        let index: Int
        
        init(parent: PhotoUploadView, index: Int) {
            self.parent = parent
            self.index = index
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true, completion: nil)
            
            if let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                    } else if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            // Update the selectedImages array with the new image
                            self?.parent.updateSelectedImage(image: image, index: self?.index ?? 0)
                        }
                    }
                }
            }
        }
    }
}

