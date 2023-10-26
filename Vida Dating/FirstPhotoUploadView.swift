import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import SDWebImageSwiftUI

struct FirstPhotoUploadView: View {
    @State var selectedImages: [UIImage?] = [nil, nil, nil, nil, nil, nil]
    @State private var coordinator: Coordinator?
    @State private var saveButtonTapped = false
    @State private var userID: String? = Auth.auth().currentUser?.uid
    @State private var isLoadingImage = false
    @State private var userProfileImageURL: URL? = nil
    @State private var userProfileImageURLs: [URL?] = [nil, nil, nil, nil, nil, nil]
    @State private var updatedImages: [UIImage?] = []
    @State private var updatedImageIndices: [Int] = []
    @State private var changedImageIndices: [Int] = []
    @State private var currentImageIndex: Int?
    
    let vidaPink = Color(red: 231/255, green: 83/255, blue: 136/255)
    
    let infoButtons: [(title: String, iconName: String, infoText: String)] = [
        ("Work", "briefcase", "Prefer not to answer for now"),
        ("Job Title", "person.fill", "Prefer not to answer for now"),
        ("School", "graduationcap.fill", "Prefer not to answer for now"),
        // Add more button data here
    ]
    
    var body: some View {
        ZStack {
            Color(red: 54/255, green: 54/255, blue: 122/255)
                .edgesIgnoringSafeArea(.all)
            
            VStack{
                HStack{
                    Spacer()
                
                    Button(action: {
                        saveButtonTapped = true
                        saveImagesToFirebase()
                        // Handle save button tap action
                    }) {
                        Text("Save")
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .onPreferenceChange(ViewWidthKey.self) { width in
                    let horizontalPadding: CGFloat = 16 // Adjust as needed
                    let offset = (width / 2) - (horizontalPadding / 2)
                    saveButtonOffset = offset
                }

                Spacer()

                Spacer() // Add a spacer to push content below
                ScrollView{
                    HStack(spacing: 10) {
                        ForEach(0..<1) { index in
                            imageView(forIndex: index)
                        }
                    }
                    // Loop through the infoButtons array to create InfoButtons dynamically
                    ForEach(infoButtons, id: \.self.title) { buttonData in
                        InfoButton(title: buttonData.title, iconName: buttonData.iconName, infoText: buttonData.infoText)
                    }
                }
                .onAppear {
                    loadImageURLsFromFirestore()

                }
            }
        }
    }
    
    struct ViewWidthKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }

    @State private var saveButtonOffset: CGFloat = 0

    func imageView(forIndex index: Int) -> some View {
        if let selectedImage = selectedImages.indices.contains(index) ? selectedImages[index] : nil {
            return AnyView(RectangleView(image: selectedImage, onTap: { index in
                presentImagePicker(index: index)
            }, index: index)
                .frame(width: 200, height: 200)
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
            .frame(width: 200, height: 200)
            .onTapGesture {
                presentImagePicker(index: index)
            })
        } else {
            // Return an empty view if both the selected images and user profile image URLs don't contain an image for the current index
            return AnyView(Color.clear.frame(width: 200, height: 200))
        }
    }

    private func saveImagesToFirebase() {
        if saveButtonTapped {
            let storageRef = Storage.storage().reference()
            let user = Auth.auth().currentUser
            let userID = user?.uid ?? ""
            
            var downloadURLs: [String] = []
            
            let group = DispatchGroup() // create a dispatch group to wait for all uploads to finish
            
            for index in changedImageIndices {
                if let image = selectedImages[index], let imageData = image.jpegData(compressionQuality: 0.5) {
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
                
                // Clear the changedImageIndices array now that we've saved the changes
                changedImageIndices.removeAll()
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
        currentImageIndex = index
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
        selectedImages[index] = image // Update the selected image at the given index
        if !changedImageIndices.contains(index) {
            changedImageIndices.append(index) // Add the index to changedImageIndices if it's not already there
        }
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
                        .frame(width: 200, height: 200) // add frame modifier to keep image size fixed
                        .cornerRadius(10)
                } else {
                    RoundedRectangle(cornerRadius: 20) // Set the corner radius to 20
                        .stroke(Color.white, lineWidth: 2) // Create a white border with 2-point width
                        .frame(width: 200, height: 200) // add frame modifier to keep the button size fixed
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 60))
                }
            }
            .onTapGesture {
                onTap(index)
            }
        }
    }

    struct InfoButton: View {
        var title: String
        var iconName: String
        var infoText: String

        var body: some View {
            Button(action: {
                // Add action for the settings button
            }) {
                HStack {
                    Text(title)
                        .padding(.leading)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    Image(systemName: iconName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.trailing)
                }
                .frame(height: 60)
                .background(
                    VStack(spacing: 0) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.white)
                            .opacity(0.3)
                            .padding(.horizontal)
                        Spacer()
                    }
                )
            }
        }
    }

    private class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: FirstPhotoUploadView
        let index: Int

        init(parent: FirstPhotoUploadView, index: Int) {
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
