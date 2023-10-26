//
//  Matches.swift
//  Vida Dating
//
//  Created by Kennion Gubler on 7/12/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore

// MARK: - MatchesViewModel
class MatchesViewModel: ObservableObject {
    @Published var matches = [Match]()
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    deinit {
        self.listener?.remove()
    }

    struct Match: Identifiable {
        let id: String // Use the conversation ID as the unique identifier.
        let conversation: Conversation
        let currentUserDisplayName: String // Add the current user's name
        let likedUserDisplayName: String // Add the liked user's name
    }
    
    // Fetch matches for the current user.
    func fetchMatches() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let currentUserRef = db.collection("users").document(currentUserID)
        
        currentUserRef.getDocument { [weak self] snapshot, error in
            guard let self = self, let userData = snapshot?.data() else {
                print("No user data found")
                return
            }
            
            guard let likedUserIDs = userData["likes"] as? [String] else {
                print("No liked users found")
                return
            }
            
            // Iterate through the list of users the current user has liked.
            for likedUserID in likedUserIDs {
                self.checkForMutualLike(currentUserID: currentUserID, likedUserID: likedUserID)
            }
        }
    }

    // Check if there is a mutual like between two users.
    private func checkForMutualLike(currentUserID: String, likedUserID: String) {
        let currentUserRef = db.collection("users").document(currentUserID)
        let likedUserRef = db.collection("users").document(likedUserID)
        
        currentUserRef.getDocument { [weak self] snapshot, error in
            guard let self = self, let currentUserData = snapshot?.data() else {
                print("Error fetching current user's data")
                return
            }
            
            likedUserRef.getDocument { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot, let likedUserData = snapshot.data() else {
                    print("Error fetching liked user's data")
                    return
                }
                
                guard let currentUserDisplayName = currentUserData["name"] as? String,
                      let likedUserDisplayName = likedUserData["name"] as? String else {
                    print("Error fetching names")
                    return
                }
                
                if let likedUserLikes = likedUserData["likes"] as? [String], likedUserLikes.contains(currentUserID) {
                    // Mutual like confirmed. Now, check if a conversation already exists or needs to be created.
                    self.ensureConversationExists(currentUserID: currentUserID, likedUserID: likedUserID, currentUserDisplayName: currentUserDisplayName, likedUserDisplayName: likedUserDisplayName)
                }
            }
        }
    }

    // Ensure a conversation exists between two users. If not, create one.
    private func ensureConversationExists(currentUserID: String, likedUserID: String, currentUserDisplayName: String, likedUserDisplayName: String) {
        let conversationsRef = db.collection("matchConversations")

        if currentUserID == likedUserID {
            // Both users are the same, do something else or handle the case as needed.
            print("Both users are the same")
            return
        }

        // Make sure the members array is always in the same order to prevent duplicate conversations.
        let members = [currentUserID, likedUserID].sorted()

        // Query for existing conversations between the two users.
        conversationsRef.whereField("members", isEqualTo: members).getDocuments { [weak self] snapshot, error in
            guard let self = self, let documents = snapshot?.documents else {
                print("Error fetching conversations")
                return
            }

            if let existingConversation = documents.first {
                // An existing conversation was found. Convert it to a 'Match' and add it to 'matches'.
                let conversation = self.convertToConversation(from: existingConversation)
                let match = Match(id: conversation.id, conversation: conversation, currentUserDisplayName: currentUserDisplayName, likedUserDisplayName: likedUserDisplayName)

                if !self.matches.contains(where: { $0.id == match.id }) {
                    self.matches.append(match)
                }
            } else {
                // No existing conversation was found. Create a new one.
                let newConversationData: [String: Any] = [
                    "name": " \(currentUserDisplayName) & \(likedUserDisplayName)", // Use user names in the conversation name.
                    "lastMessage": "",
                    "members": members,
                    "timestamp": FieldValue.serverTimestamp()
                ]

                // Add a new conversation document.
                conversationsRef.addDocument(data: newConversationData) { error in
                    if let error = error {
                        print("Error creating conversation: \(error)")
                        return
                    }
                    // Fetch the newly created conversation to ensure it's added to 'matches'.
                    self.ensureConversationExists(currentUserID: currentUserID, likedUserID: likedUserID, currentUserDisplayName: currentUserDisplayName, likedUserDisplayName: likedUserDisplayName)
                }
            }
        }
    }

    // Helper method to convert a Firestore document to a 'Conversation' model.
    private func convertToConversation(from document: QueryDocumentSnapshot) -> Conversation {
        let data = document.data()
        let id = document.documentID
        let name = data["name"] as? String ?? "Unnamed Conversation"
        let lastMessage = data["lastMessage"] as? String ?? ""
        let timestamp = data["timestamp"] as? Timestamp ?? Timestamp()
        let members = data["members"] as? [String] ?? []
        let photoURLs = data["photoURLs"] as? [String] ?? []

        return Conversation(id: id, name: name, message: lastMessage, timestamp: timestamp, members: members, photoURLs: photoURLs)
    }
}

// MARK: - MatchesView
struct MatchesView: View {
    @ObservedObject var viewModel = MatchesViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 54/255, green: 54/255, blue: 122/255)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.matches) { match in
                            NavigationLink(destination: ConversationView(conversation: match.conversation)) { // Replace with your actual conversation view.
                                VStack(alignment: .leading) {
                                    Text(" \(match.currentUserDisplayName) & \(match.likedUserDisplayName)") // Display user names.
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text(match.conversation.message)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(red: 54/255, green: 54/255, blue: 122/255))
                            }
                            Divider()
                                .background(Color.white)
                                .padding(.horizontal)
                        }
                    }
                }
                .navigationBarTitle("Matches", displayMode: .large)
                .foregroundColor(.white)
            }
        }
        .onAppear {
            viewModel.fetchMatches()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MatchesView_Previews: PreviewProvider {
    static var previews: some View {
        MatchesView()
    }
}
