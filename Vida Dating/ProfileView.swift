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
    @State private var isLoadingImage = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 30/255, green: 30/255, blue: 60/255)
                    .ignoresSafeArea()
                VStack {
                    Spacer()

                    if isLoadingImage {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        if let imageUrl = userProfileImageURL {
                            URLImage(imageUrl) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                    .padding(.bottom, 30)
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                                .padding(.bottom, 30)
                        }
                    }

                    VStack(spacing: 0) {
                        NavigationLink(destination: PhotoUploadView()) {
                            Text("Edit Profile")
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color.vidaPink, lineWidth: 0.5)
                                        .background(Color.blue.opacity(0.2))
                                )
                                .foregroundColor(Color.vidaPink)
                        }
                        Button(action: {}) {
                            Text("Edit Hobbies")
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color.vidaPink, lineWidth: 0.5)
                                        .background(Color.blue.opacity(0.2))
                                )
                                .foregroundColor(Color.vidaPink)
                        }
                    }
                    .frame(maxWidth: 350)
                    .background(Color.vidaBackground)
                    .padding()
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
                if let photoURL = document.data()?["photoURL0"] as? String {
                    if let url = URL(string: photoURL) {
                        self.userProfileImageURL = url
                    } else {
                        print("Invalid photo URL for current user.")
                    }
                } else {
                    print("No photoURL found for current user.")
                }
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
