//
//  ConversationsView.swift
//  Vida Dating
//
//  Created by Kennion Gubler on 4/20/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage

struct Conversation: Identifiable {
    let id: String
    let name: String
    let message: String
    let timestamp: Timestamp
    let members: [String]
}

class ConversationsViewModel: ObservableObject {
    @Published var conversations = [Conversation]()
    private var listener: ListenerRegistration?
    
    func fetchConversations() {
        let db = Firestore.firestore()
        let uid = Auth.auth().currentUser!.uid
        let conversationsRef = db.collectionGroup("conversations").whereField("members", arrayContains: uid)
            
        self.listener = conversationsRef.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error fetching conversations: \(error)")
                return
            }
                
            guard let documents = querySnapshot?.documents else {
                print("No conversations found.")
                return
            }
                
            let conversations = documents.map { document -> Conversation in
                let data = document.data()
                let id = document.documentID
                let name = data["name"] as? String ?? ""
                let message = data["lastMessage"] as? String ?? ""
                let timestamp = data["timestamp"] as? Timestamp ?? Timestamp()
                let members = data["members"] as? [String] ?? []
                return Conversation(id: id, name: name, message: message, timestamp: timestamp, members: members)
            }
                
            DispatchQueue.main.async {
                self.conversations = conversations
            }
                
            print("Fetched \(conversations.count) conversations")
            print("Updated conversations: \(conversations)")
        }
    }
    func createRandomGroupConversations() {
        let db = Firestore.firestore()
        
        db.collection("users").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No users found.")
                return
            }
            
            let randomMembers = documents
                .shuffled()
                .prefix(5)
                .map { $0.documentID }
            
            let conversationData: [String: Any] = [
                "name": "Group Conversation",
                "lastMessage": "",
                "members": randomMembers,
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            db.collection("conversations").addDocument(data: conversationData) { error in
                if let error = error {
                    print("Error creating conversation: \(error)")
                } else {
                    print("Created conversation with members \(randomMembers)")
                }
            }
        }
    }


    
    deinit {
        self.listener?.remove()
    }
}

struct ConversationsView: View {
    @ObservedObject var viewModel = ConversationsViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.conversations) { conversation in
                NavigationLink(destination: ConversationView(conversation: conversation)) {
                    VStack(alignment: .leading) {
                        Text(conversation.name)
                            .font(.headline)
                        Text(conversation.message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationBarTitle("Conversations")
            .navigationBarItems(trailing:Button(action: {
                self.viewModel.createRandomGroupConversations()
            }) {
                Text("Create")
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            })

            .onAppear {
                self.viewModel.fetchConversations()
            }
        }
    }
}
