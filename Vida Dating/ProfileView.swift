//
//  ProfileView.swift
//  Gild_Dating
//
//  Created by Kennion Gubler on 4/11/23.
//

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
                            NavigationLink(destination: PhotoUploadView()) {
                                URLImage(imageUrl) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                        .padding(.bottom, 30)
                                }
                            }
                        } else {
                            NavigationLink(destination: PhotoUploadView()) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                    .padding(.bottom, 30)
                            }
                        }
                    }
                    
                    // Display the user's name and age
                    if let name = userName, let age = userAge {
                        Text("\(name), \(age)")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                    }
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
                        print("Invalid photo URL for current user.")
                    }
                } else {
                    print("No photoURLs found for current user.")
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
