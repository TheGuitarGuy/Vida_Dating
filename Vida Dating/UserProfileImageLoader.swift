//
//  UserProfileImageLoader.swift
//  Vida Dating
//
//  Created by Kennion Gubler on 4/23/23.
//

import Foundation
import Firebase
import FirebaseFirestore

class UserProfileImageLoader: ObservableObject {
    @Published var profileImageURL: URL?

    func loadProfileImage(for userID: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { document, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
            } else if let document = document, document.exists {
                if let photoURL = document.data()?["photoURL"] as? String {
                    if let url = URL(string: photoURL) {
                        self.profileImageURL = url
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
