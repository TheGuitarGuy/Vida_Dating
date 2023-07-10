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
    @State private var otherUserProfileImageURLs: [String: URL?] = [:]
    
    var body: some View {
        HStack(alignment: .bottom) {
            if let url = otherUserProfileImageURLs[message.senderId], !isCurrentUserMessage() {
                WebImage(url: url!)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .padding(.leading, 8)
                    .onTapGesture {
                        let personalProfileView = PersonalProfileView(otherUserID: message.senderId)
                        UIApplication.shared.windows.first?.rootViewController?.present(UIHostingController(rootView: personalProfileView), animated: true, completion: nil)
                    }
            }
            VStack(alignment: isCurrentUserMessage() ? .trailing : .leading) {
                HStack {
                    Text(message.text)
                        .padding()
                        .background(isCurrentUserMessage() ? Color(red: 145 / 255, green: 0 / 255, blue: 254 / 255) : Color(red: 128/255, green: 134/255, blue: 200/255))
                        .foregroundColor(isCurrentUserMessage() ? .vidaWhite : .vidaWhite)
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
        let dispatchGroup = DispatchGroup()
        
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
                    print("No photoURLs found for user.")
                }
            } else {
                print("User document not found.")
            }
        }
        
        dispatchGroup.enter()

        db.collection("users").document(message.senderId).getDocument { document, error in
            self.isLoadingImage = false
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
            } else if let document = document, document.exists {
                if let photoURLs = document.data()?["photoURLs"] as? [String] {
                    if let url = URL(string: photoURLs[0]) {
                        self.otherUserProfileImageURLs[message.senderId] = url
                    }
                } else {
                    print("No photoURLs found for user.")
                }
            } else {
                print("User document not found.")
            }
            dispatchGroup.leave()
        }
    }
}


