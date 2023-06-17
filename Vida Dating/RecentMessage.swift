////
////  RecentMessage.swift
////  Vida Dating
////
////  Created by Kennion Gubler on 4/21/23.
////
//
//import Foundation
//import FirebaseFirestoreSwift
//import Firebase
//
//struct RecentMessage: Identifiable {
//    let id: String
//    let text: String
//    let fromUserId: String
//    let toUserId: String
//    let timestamp: Timestamp
//    
//    init(id: String, data: [String: Any]) {
//        self.id = id
//        self.text = data["text"] as? String ?? ""
//        self.fromUserId = data["fromUserId"] as? String ?? ""
//        self.toUserId = data["toUserId"] as? String ?? ""
//        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp()
//    }
//}
