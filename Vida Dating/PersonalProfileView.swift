//
//  PersonalProfileView.swift
//  Vida Dating
//
//  Created by Kennion Gubler on 5/2/23.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

struct PersonalProfileView: View {
    let otherUserID: String
    @State private var selectedImageIndex = 0
    @State private var userProfileImageURLs: [URL?] = []
    @State private var userName: String = ""
    @State private var userAge: Int = 0
    @State private var isLoadingImage = false
    
    var body: some View {
        ZStack {
            Color(red: 30/255, green: 30/255, blue: 60/255)
                .edgesIgnoringSafeArea(.all)
            GeometryReader { geometry in
                VStack {
                    if isLoadingImage {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        if userProfileImageURLs.isEmpty {
                            Text("No images to display.")
                        } else {
                            if let url = userProfileImageURLs[selectedImageIndex] {
                                WebImage(url: url)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.height * 0.9)  // Adjust the 0.9 to your liking
                                    .clipped()
                                    .overlay(
                                        VStack {
                                            Spacer()
                                            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.95), Color.black.opacity(0)]), startPoint: .bottom, endPoint: .top)
                                                .frame(maxHeight: UIScreen.main.bounds.height / 3)
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                    )
                                    .overlay(
                                        VStack {
                                            Spacer()
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text("\(userName), \(userAge)")
                                                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                                                        .foregroundColor(.white)
                                                    HStack(alignment: .center, spacing: 10) {
                                                        ForEach(userProfileImageURLs.indices) { index in
                                                            Circle()
                                                                .frame(width: 10, height: 10)
                                                                .foregroundColor(index == selectedImageIndex ? Color.vidaPink : Color.white)
                                                        }
                                                    }
                                                }
                                                Spacer()
                                            }
                                        }.padding()
                                    )
                                    .edgesIgnoringSafeArea(.all)
                                    .onTapGesture {
                                        selectedImageIndex = (selectedImageIndex + 1) % userProfileImageURLs.count
                                    }
                            } else {
                                Color.gray
                                    .edgesIgnoringSafeArea(.all)
                            }
                        }
                    }
                    Spacer()
                }
                .onAppear(perform: loadUserProfileImageURLsFromFirestore)
            }
        }
    }
    
    private func loadUserProfileImageURLsFromFirestore() {
        isLoadingImage = true
        let db = Firestore.firestore()
        db.collection("users").document(otherUserID).getDocument { document, error in
            self.isLoadingImage = false
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
            } else if let document = document, document.exists {
                if let photoURLs = document.data()?["photoURLs"] as? [String] {
                    self.userProfileImageURLs = photoURLs.compactMap { URL(string: $0) }
                    if !self.userProfileImageURLs.isEmpty {
                        self.selectedImageIndex = 0
                    }
                } else {
                    print("No photoURLs found for user.")
                }
                
                self.userName = document.data()?["name"] as? String ?? "No name"
                self.userAge = document.data()?["age"] as? Int ?? 0
            } else {
                print("User document not found.")
            }
        }
    }
}

struct PersonalProfileView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalProfileView(otherUserID: "12345")
    }
}
