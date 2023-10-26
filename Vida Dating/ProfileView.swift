import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import URLImage
import FirebaseFirestoreSwift

struct ProfileView: View {
    @State private var userID: String? = Auth.auth().currentUser?.uid
    @State private var userProfileImageURL: URL? = nil
    @State private var userName: String? = nil
    @State private var userAge: Int? = nil
    @State private var isLoadingImage = false
    @State private var isEditingProfile = false // New state variable for navigation
    @State private var isNavigatingToSafety = false // New state variable for navigation to SafetyView
    @State private var isNavigatingToSettings = false // New state variable for navigation to SettingsView

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 54/255, green: 54/255, blue: 122/255)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()

                    if isLoadingImage {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        if let imageUrl = userProfileImageURL {
                            NavigationLink(destination: PhotoUploadView(), isActive: $isEditingProfile) {
                                EmptyView() // NavigationLink starts as inactive
                            }
                            // Use URLImage with caching
                            URLImage(imageUrl, failure: { error, _ in
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                    .padding(.bottom, 30)
                            }, content: { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                    .padding(.bottom, 30)
                            })
                        } else {
                            NavigationLink(destination: PhotoUploadView(), isActive: $isEditingProfile) {
                                EmptyView() // NavigationLink starts as inactive
                            }
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                .padding(.bottom, 30)
                        }
                    }

                    // Display the user's name and age
                    if let name = userName, let age = userAge {
                        Text("\(name), \(age)")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                    }

                    Spacer()

                    // Edit Profile Button
                    Button(action: {
                        isEditingProfile = true // Set to true to activate NavigationLink
                    }) {
                        HStack {
                            Text("Edit Profile")
                                .padding(.leading)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Spacer()

                            Image(systemName: "pencil")
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

                    // Settings Button with NavigationLink
                    NavigationLink(destination: SettingsView(), isActive: $isNavigatingToSettings) {
                        EmptyView() // NavigationLink starts as inactive
                    }
                    Button(action: {
                        // Add action for Settings button
                        isNavigatingToSettings = true // Set to true to activate NavigationLink
                    }) {
                        HStack {
                            Text("Settings")
                                .padding(.leading)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Spacer()

                            Image(systemName: "gearshape.fill")
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

                    // Safety Button with NavigationLink
                    NavigationLink(destination: SafetyView(), isActive: $isNavigatingToSafety) {
                        EmptyView() // NavigationLink starts as inactive
                    }
                    Button(action: {
                        // Add action for Safety button
                        isNavigatingToSafety = true // Set to true to activate NavigationLink
                    }) {
                        HStack {
                            Text("Safety")
                                .padding(.leading)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Spacer()

                            Image(systemName: "lightbulb")
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
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.white)
                                    .opacity(0.3)
                                    .padding(.horizontal)
                            }
                        )
                    }

                    Spacer()
                }
            }
            .onAppear {
                loadImageURLFromFirestore()
            }
        }
    }

    func loadImageURLFromFirestore() {
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
                if let photoURLs = document.data()?["photoURLs"] as? [String], !photoURLs.isEmpty {
                    if let url = URL(string: photoURLs[0]) {
                        self.userProfileImageURL = url
                    } else {
                        print("Invalid photo URL for the current user.")
                    }
                } else {
                    print("No photoURLs found for the current user.")
                }

                // Fetching the user's name and age
                self.userName = document.data()?["name"] as? String
                self.userAge = document.data()?["age"] as? Int
            } else {
                print("Current user document not found.")
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
