//
//  ConversationView.swift
//  Vida Dating
//
//  Created by Kennion Gubler on 4/23/23.
//

import SwiftUI
import Firebase

struct Message: Identifiable, Codable {
    let id: String
    let text: String
    let senderId: String
    let timestamp: Timestamp

    func toDictionary() -> [String: Any] {
        return ["id": id,"text": text,"senderId": senderId,"timestamp": timestamp]
    }
}

struct CustomTitleView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
    }
    
    var titleString: String {
        return title
    }
}

struct ConversationView: View {
    let conversation: Conversation
    let db = Firestore.firestore()
    @State var messageText: String = ""
    @ObservedObject var viewModel: MessagesViewModel
    
    // Add a cachedMessages array to store fetched messages
    @State var cachedMessages: [Message] = []
    
    init(conversation: Conversation) {
        self.conversation = conversation
        self.viewModel = MessagesViewModel(conversation: conversation)
    }
    
    var body: some View {
        ZStack{
            Color(red: 54/255, green: 54/255, blue: 122/255)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Rectangle()
                    .fill(Color(red: 54/255, green: 54/255, blue: 122/255))
                    .frame(height: UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
                    .edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            HStack {
                                if message.senderId == Auth.auth().currentUser?.uid {
                                    Spacer()
                                    MessageBubble(message: message)
                                } else {
                                    MessageBubble(message: message)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                
                HStack {
                    TextField("", text: $messageText)
                        .modifier(PlaceholderStyle(showPlaceHolder: messageText.isEmpty,
                                                   placeholder: "Type something sweet: "))
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                        .foregroundColor(.vidaWhite)
                        .accentColor(.vidaPink)
                    
                    Button(action: {
                        sendMessage()
                    }, label: {
                        Image(systemName: "message")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.vidaPink)
                            .clipShape(Circle())
                    })
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    CustomTitleView(title: conversation.name)
                }
            }
            .onAppear {
                // Check if we have already fetched messages for this conversation
                if cachedMessages.isEmpty {
                    self.viewModel.fetchMessages()
                } else {
                    // If messages are cached, use them
                    self.viewModel.messages = cachedMessages
                }
            }
        }
    }
    
    private func sendMessage() {
        guard let currentUser = Auth.auth().currentUser else { return }
        print(currentUser)
        let conversationId = conversation.id
        if conversationId.isEmpty {
            print("Conversation ID is empty.")
            return // Return early if conversation ID is empty
        }
        let messageRef = db.collection("messages").document()
        let messageId = messageRef.documentID.isEmpty ? UUID().uuidString : messageRef.documentID // assign message ID to a variable
        let messageData: [String: Any] = [
            "id": messageId,
            "text": messageText,
            "senderId": currentUser.uid,
            "conversationId": conversationId,
            "timestamp": Timestamp()
        ]
        messageRef.setData(messageData) { error in
            if let error = error {
                print("Error sending message: \(error)")
            } else {
                print("Message sent successfully")
                self.messageText = ""
                
                // Add the sent message to the cache
                self.cachedMessages.append(Message(id: messageId, text: messageText, senderId: currentUser.uid, timestamp: Timestamp()))
            }
        }
        let members = conversation.members.filter { $0 != currentUser.uid }
        for _ in members {
            let memberRef = db.collection("messages").document(messageId) // use messageId instead of messageRef.documentID
            print("messageRef path: \(messageRef.path)")
            print("messageData: \(messageData)")
            memberRef.setData(messageData)
            print("messageRef path: \(messageRef.path)")
            print("messageData: \(messageData)")
        }
    }
}

class MessagesViewModel: ObservableObject {
    @Published var messages = [Message]()
    private var listener: ListenerRegistration?
    let conversation: Conversation
    
    init(conversation: Conversation) {
        self.conversation = conversation
    }
    
    func fetchMessages() {
        let db = Firestore.firestore()
        let messagesRef = db.collection("messages").whereField("conversationId", isEqualTo: conversation.id)
        print(conversation.id)
        print(conversation.id)
        print(conversation.id)
        print(conversation.id)
        self.listener = messagesRef.order(by: "timestamp").addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error fetching messages: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No messages found.")
                return
            }
            
            let messages = documents.compactMap { document -> Message? in
                let data = document.data()
                let id = document.documentID
                let text = data["text"] as? String ?? ""
                let senderId = data["senderId"] as? String ?? ""
                let timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
                return Message(id: id, text: text, senderId: senderId, timestamp: timestamp)
            }
            
            // Update the view model's messages and cache
            self.messages = messages
        }
    }
    
    func stopListening() {
        self.listener?.remove()
    }
}
