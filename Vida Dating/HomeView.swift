//
//  HomeView.swift
//  Pod_Dating
//
//  Created by Kennion Gubler on 4/11/23.
//
import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseFirestore

struct HomeView: View {
    @State private var currentIndex = 0
    @State private var profiles: [UserProfile] = []
    @State private var likedUserIDs: Set<String> = []
    @State private var isMatchedViewPresented = false

    struct UserProfile {
        let userId: String
        let photoURL: String
        let bioText: String
        let name: String // Add the name property
        let age: Int // Add the age property
    }

    var body: some View {
        ZStack {
            Color(red: 54/255, green: 54/255, blue: 122/255)
                .edgesIgnoringSafeArea(.all)

            VStack {
                if let currentProfile = profiles.indices.contains(currentIndex) ? profiles[currentIndex] : nil {
                    // Display current user profile
                    UserProfileView(userProfile: currentProfile, goToNextProfile: goToNextProfile, handleLike: handleLike)
                } else {
                    Text("No profiles available.")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            fetchConversations()
        }
        .sheet(isPresented: $isMatchedViewPresented) {
            YouMatchedView(dismissAction: {
                // Dismiss the YouMatchedView and continue browsing other profiles
                isMatchedViewPresented = false
                goToNextProfile()
                // Here, you might want to reset or perform some action after dismissing.
            })
        }

    }

    private func fetchConversations() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("No current user ID")
            return
        }
        
        let conversationsRef = Firestore.firestore().collection("conversations")

        conversationsRef.getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("No conversations found: \(String(describing: error))")
                return
            }

            for document in documents {
                guard let members = document.get("members") as? [String] else {
                    print("Failed to process conversation snapshot: \(document)")
                    continue
                }

                if members.contains(currentUserID) {
                    let otherUserIDs = members.filter { $0 != currentUserID }

                    for userID in otherUserIDs {
                        print("Fetching user profile for user ID: \(userID)")
                        fetchUserProfile(for: userID)
                    }
                }
            }
        }
    }

    private func fetchUserProfile(for userID: String) {
        let usersRef = Firestore.firestore().collection("users")

        usersRef.document(userID).getDocument { snapshot, error in
            guard let userData = snapshot?.data(),
                  let photoURLs = userData["photoURLs"] as? [String],
                  let photoURL = photoURLs.first,
                  let bioText = userData["bioText"] as? String,
                  let name = userData["name"] as? String, // Add the name property
                  let age = userData["age"] as? Int // Add the age property
            else {
                print("Failed to get user profile for ID \(userID): \(String(describing: error))")
                return
            }

            let userProfile = UserProfile(userId: userID, photoURL: photoURL, bioText: bioText, name: name, age: age)
            DispatchQueue.main.async {
                // Check if the user profile ID is already in the likedUserIDs set
                if !likedUserIDs.contains(userID) {
                    profiles.append(userProfile)
                }
            }
        }
    }

    private func goToNextProfile() {
        currentIndex += 1
        if currentIndex >= self.profiles.count {
            currentIndex = 0
        }
    }

    private func handleLike() {
        guard let currentUserID = Auth.auth().currentUser?.uid,
              let userProfile = profiles.indices.contains(currentIndex) ? profiles[currentIndex] : nil else {
            return
        }

        let likedUserID = userProfile.userId

        let usersRef = Firestore.firestore().collection("users")
        let currentUserRef = usersRef.document(currentUserID)

        // Check if the liked user also liked the current user
        currentUserRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching current user document: \(error)")
                return
            }

            if let data = snapshot?.data(),
               let likes = data["likes"] as? [String],
               likes.contains(likedUserID) {
                // Check if the liked user also liked the current user
                let likedUserRef = usersRef.document(likedUserID)

                likedUserRef.getDocument { likedUserSnapshot, likedUserError in
                    if let likedUserError = likedUserError {
                        print("Error fetching liked user document: \(likedUserError)")
                        return
                    }

                    if let likedUserData = likedUserSnapshot?.data(),
                       let likedUserLikes = likedUserData["likes"] as? [String],
                       likedUserLikes.contains(currentUserID) {
                        // It's a mutual match, so present the YouMatchedView
                        DispatchQueue.main.async {
                            isMatchedViewPresented = true
                        }
                    } else {
                        // It's not a mutual match, proceed as before
                        currentUserRef.updateData(["likes": FieldValue.arrayUnion([likedUserID])]) { error in
                            if let error = error {
                                print("Failed to log like: \(error)")
                            } else {
                                // Add the liked user ID to the likedUserIDs set
                                likedUserIDs.insert(likedUserID)

                                // Move to the next profile
                                goToNextProfile()
                            }
                        }
                    }
                }
            } else {
                // It's not a mutual match, proceed as before
                currentUserRef.updateData(["likes": FieldValue.arrayUnion([likedUserID])]) { error in
                    if let error = error {
                        print("Failed to log like: \(error)")
                    } else {
                        // Add the liked user ID to the likedUserIDs set
                        likedUserIDs.insert(likedUserID)

                        // Move to the next profile
                        goToNextProfile()
                    }
                }
            }
        }
    }


}

struct UserProfileView: View {
    let userProfile: HomeView.UserProfile
    let goToNextProfile: () -> Void
    let handleLike: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    if let url = URL(string: userProfile.photoURL) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.7)
                        .clipped()
                        .edgesIgnoringSafeArea(.top)
                        .overlay(
                            VStack {
                                Text("\(userProfile.name), \(userProfile.age)")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.leading, 20)
                                    .padding(.bottom, 20)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        )
                    } else {
                        Text("Failed to load image.")
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        Text("Bio:")
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.leading)

                        Text(userProfile.bioText)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .padding(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .layoutPriority(1)

                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)

                    HStack {
                        Button(action: {
                            // Handle "I'm not interested" button tap
                            goToNextProfile()
                        }) {
                            Image(systemName: "xmark")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.black)
                        }
                        .frame(width: 70, height: 70)
                        .background(Color.white)
                        .cornerRadius(50)
                        .padding()

                        Spacer()

                        Button(action: {
                            // Handle "I'm interested" button tap
                            handleLike()
                        }) {
                            Image(systemName: "heart.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                        }
                        .frame(width: 70, height: 70)
                        .background(Color.pink)
                        .cornerRadius(50)
                        .padding()
                    }
                    .padding(.horizontal, 50)
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, geometry.safeAreaInsets.bottom)
            }
            .edgesIgnoringSafeArea(.top)
            .foregroundColor(.white)
        }
    }
}




struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
