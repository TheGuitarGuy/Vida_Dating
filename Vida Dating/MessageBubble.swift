//
//  MessageBubble.swift
//  Gild_Dating
//
//  Created by Kennion Gubler on 4/19/23.
//

import SwiftUI
import Firebase
import SDWebImageSwiftUI

struct MessageBubble: View {
    var message: Message
    @State private var userID: String? = Auth.auth().currentUser?.uid
    @State private var userProfileImageURL: URL? = nil
    @State private var isLoadingImage = false
    @State private var userProfileImageURLs: [URL?] = []
    @State private var otherUserIDs: [String] = []
    @State private var otherUserProfileImageURLs: [URL?] = []
    
    var body: some View {
        HStack(alignment: .bottom) {
            if let url = otherUserProfileImageURLs.first(where: { $0 != nil }), !isCurrentUserMessage() {
                WebImage(url: url!)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .padding(.leading, 8)
                    .onTapGesture {
                        if let otherUserID = otherUserIDs.first {
                            let personalProfileView = PersonalProfileView(otherUserID: otherUserID)
                            UIApplication.shared.windows.first?.rootViewController?.present(UIHostingController(rootView: personalProfileView), animated: true, completion: nil)
                        }
                    }
            }
            VStack(alignment: isCurrentUserMessage() ? .trailing : .leading) {
                HStack {
                    Text(message.text)
                        .padding()
                        .background(isCurrentUserMessage() ? Color(red: 145 / 255, green: 0 / 255, blue: 254 / 255) : Color(red: 219/255, green: 217/255, blue: 219/255))
                        .foregroundColor(isCurrentUserMessage() ? .vidaWhite : .vidaBackground)
                        .cornerRadius(30)
                }
                .frame(maxWidth: 300, alignment: isCurrentUserMessage() ? .trailing : .leading)
            }
            .frame(maxWidth: .infinity, alignment: isCurrentUserMessage() ? .trailing : .leading)
            if let url = userProfileImageURL, isCurrentUserMessage() {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .padding(.trailing, 8)
                    .onTapGesture {
                        let personalProfileView = PersonalProfileView(otherUserID: userID!)
                        UIApplication.shared.windows.first?.rootViewController?.present(UIHostingController(rootView: personalProfileView), animated: true, completion: nil)
                    }
            }
        }
        .onAppear(perform: loadUserProfileImageURLsFromFirestore)
    }

    
    func isCurrentUserMessage() -> Bool {
        if let currentUser = Auth.auth().currentUser {
            return message.senderId == currentUser.uid
        }
        return false
    }
    
    func loadUserProfileImageURLsFromFirestore() {
        guard let userID = userID else {
            print("No user is signed in.")
            return
        }
        
        isLoadingImage = true
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup() // Create a DispatchGroup
        
        db.collection("users").document(userID).getDocument { document, error in
            self.isLoadingImage = false
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
            } else if let document = document, document.exists {
                if let photoURLs = document.data()?["photoURLs"] as? [String] {
                    if let url = URL(string: photoURLs[0]) {
                        self.userProfileImageURL = url
                    }
                } else {
                    print("No photoURLs found for other user.")
                    // Use default image URL here
                    if let defaultURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/vida-dating.appspot.com/o/profile.png?alt=media&token=f888cc09-fa4c-4e4f-bb34-0908a2c88645") {
                        self.otherUserProfileImageURLs.append(defaultURL)
                    }
                }
            } else {
                print("Current user document not found.")
            }
        }
        
        dispatchGroup.enter() // Enter the DispatchGroup before the Firestore query

        db.collection("conversations").whereField("members", arrayContains: userID).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching conversations: \(error.localizedDescription)")
            } else if let snapshot = snapshot {
                self.otherUserIDs = snapshot.documents.reduce([]) { (result, document) in
                    var result = result
                    if let members = document.data()["members"] as? [String] {
                        let otherUserIDs = members.filter { $0 != userID }
                        result.append(contentsOf: otherUserIDs)
                    }
                    return result
                }

            } else {
                print("No conversations found.")
            }

            dispatchGroup.leave() // Notify the DispatchGroup that the async task is done
        }

        dispatchGroup.notify(queue: .main) {
            // This block will be called when all async tasks in the DispatchGroup are done
            print(self.otherUserIDs) // Print the otherUserIDs array here

            // Call the method to load other user profile images
            self.loadOtherUserProfileImages()
        }
    }
    func loadOtherUserProfileImages() {
        let db = Firestore.firestore()
        
        // Iterate over each conversation and its messages
        print("YOOOOO")
        print(otherUserIDs)
        for otherUserID in otherUserIDs {
            db.collection("messages")
                .whereField("senderId", isEqualTo: otherUserID)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        print("Error fetching messages for user \(otherUserID): \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        print("No messages found for user \(otherUserID).")
                        return
                    }
                    
                    // Get the latest message document for the user
                    let latestMessageDocument = documents.sorted(by: { ($0["timestamp"] as? Timestamp)?.dateValue() ?? Date() > ($1["timestamp"] as? Timestamp)?.dateValue() ?? Date() }).first
                    
                    if let senderID = latestMessageDocument?.data()["senderId"] as? String {
                        db.collection("users").document(senderID).getDocument { userDocument, userError in
                            if let userError = userError {
                                print("Error fetching user document for sender ID \(senderID): \(userError.localizedDescription)")
                                // Use default image URL here
                                if let defaultURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/vida-dating.appspot.com/o/profile.png?alt=media&token=f888cc09-fa4c-4e4f-bb34-0908a2c88645") {
                                    DispatchQueue.main.async {
                                        self.otherUserProfileImageURLs.append(defaultURL)
                                    }
                                }
                            } else if let userDocument = userDocument, userDocument.exists {
                                if let photoURLs = userDocument.data()?["photoURLs"] as? [String], let firstURLString = photoURLs.first, let url = URL(string: firstURLString) {
                                    DispatchQueue.main.async {
                                        self.otherUserProfileImageURLs.append(url)
                                    }
                                } else {
                                    print("No photoURLs found for sender ID \(senderID).")
                                    // Use default image URL here
                                    if let defaultURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/vida-dating.appspot.com/o/profile.png?alt=media&token=f888cc09-fa4c-4e4f-bb34-0908a2c88645") {
                                        DispatchQueue.main.async {
                                            self.otherUserProfileImageURLs.append(defaultURL)
                                        }
                                    }
                                }
                            } else {
                                print("User document not found for sender ID \(senderID).")
                                // Use default image URL here
                                if let defaultURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/vida-dating.appspot.com/o/profile.png?alt=media&token=f888cc09-fa4c-4e4f-bb34-0908a2c88645") {
                                    DispatchQueue.main.async {
                                        self.otherUserProfileImageURLs.append(defaultURL)
                                    }
                                }
                            }
                        }
                    } else {
                        print("Sender ID not found in message document.")
                        // Use default image URL here
                        if let defaultURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/vida-dating.appspot.com/o/profile.png?alt=media&token=f888cc09-fa4c-4e4f-bb34-0908a2c88645") {
                        DispatchQueue.main.async {
                        self.otherUserProfileImageURLs.append(defaultURL)
                        }
                    }
                }
            }
        }
    }
}

