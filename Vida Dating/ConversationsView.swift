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
    let photoURLs: [String]
}

class ConversationsViewModel: ObservableObject {
    @Published var conversations = [Conversation]()
    @Published var isRefreshing = false
    private var listener: ListenerRegistration?
    private var lastDocument: DocumentSnapshot?
    
    func fetchConversationsBatch() {
        let db = Firestore.firestore()
        let uid = Auth.auth().currentUser!.uid
        var conversationsRef = db.collectionGroup("conversations")
            .whereField("members", arrayContains: uid)
            .order(by: "timestamp", descending: true)
            .limit(to: 10) // Adjust the batch size as needed
        
        // If lastDocument is set, start the query after it
        if let lastDoc = lastDocument {
            conversationsRef = conversationsRef.start(afterDocument: lastDoc)
        }
        
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
                let name = self.conversationTitle(for: data)
                let message = data["lastMessage"] as? String ?? ""
                let timestamp = data["timestamp"] as? Timestamp ?? Timestamp()
                let members = data["members"] as? [String] ?? []
                let photoURLs = data["photoURLs"] as? [String] ?? []
                return Conversation(id: id, name: name, message: message, timestamp: timestamp, members: members, photoURLs: photoURLs)
            }
            
            DispatchQueue.main.async {
                // Append the new batch of conversations to the existing list
                self.conversations.append(contentsOf: conversations)
            }
            
            // Update lastDocument to keep track of the last document in this batch
            if let lastDoc = querySnapshot?.documents.last {
                self.lastDocument = lastDoc
            }
        }
    }
    
    // Call this function to load more conversations when the user scrolls
    func loadMoreConversations() {
        fetchConversationsBatch()
    }
    
    func refreshConversations() {
        self.isRefreshing = true  // Set to true at refresh start

        // Cancel any existing listener before refreshing
        self.listener?.remove()

        // Clear existing conversations
        self.conversations = []

        // Reset the lastDocument for pagination
        self.lastDocument = nil

        // Fetch the initial batch of conversations again
        self.fetchConversationsBatch()

        // Assuming fetchConversationsBatch is async and can notify when the task is done,
        // we need to set isRefreshing to false when it completes.
        // If fetchConversationsBatch cannot notify, you might need to modify it to allow for a completion handler.
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
                .prefix(10)
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

    // Function to get the conversation title based on members
    private func conversationTitle(for data: [String: Any]) -> String {
        // Modify this function to return the conversation title based on the members
        // Example implementation:
        let members = data["members"] as? [String] ?? []
        return "Monterey Bonfire with \(members.count) people"
    }
}

struct ConversationsView: View {
    @ObservedObject var viewModel = ConversationsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 54/255, green: 54/255, blue: 122/255)
                    .edgesIgnoringSafeArea(.all)

                // Start modifications here
                ScrollView {
                    VStack(spacing: 0) {
                        if viewModel.isRefreshing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5) // Scale up the loader
                                .padding()
                        }
                        ForEach(viewModel.conversations) { conversation in
                            NavigationLink(destination: ConversationView(conversation: conversation)) {
                                VStack(alignment: .leading) {
                                    Text(conversation.name)
                                        .font(.headline)
                                        .foregroundColor(.vidaWhite)
                                    Text(conversation.message)
                                        .font(.subheadline)
                                        .foregroundColor(.vidaWhite)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(red: 54/255, green: 54/255, blue: 122/255))
                            }
                            Divider()
                                .background(Color.vidaWhite)
                                .padding(.horizontal)
                        }
                    }
                    .refreshable {
                        await viewModel.refreshConversations()
                    }
                    .onAppear {
                        self.viewModel.fetchConversationsBatch()
                    }                }
                // End modifications here
                
                .navigationBarTitle("Your conversations", displayMode: .large)
                .foregroundColor(.vidaWhite)
                .navigationBarItems(trailing:
                    Button(action: {
                        self.viewModel.createRandomGroupConversations()
                    }) {
                        Text("Create")
                            .fontWeight(.bold)
                            .foregroundColor(.vidaWhite)
                    }
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.vidaWhite)
    }
}
