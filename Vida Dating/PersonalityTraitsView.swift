//
//  PersonalityTraitsView.swift
//  Gild_Dating
//
//  Created by Kennion Gubler on 3/26/23.
//

import SwiftUI
import Firebase

struct HobbyButton: View {
    var hobby: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(hobby)
                .foregroundColor(.white)
                .padding()
                .background(isSelected ? Color.blue : Color.vidaPink)
                .cornerRadius(500)
                .font(.system(size: 12, weight: Font.Weight.bold))
        }
    }
}

struct PersonalityTraitsView: View {
    @State private var showDetail = false
    @State private var navigateToPhotoUploadView = false
    @State private var selectedHobbies: [String] = []
    @State private var newHobby: String = "" {
        didSet {
            if newHobby.count > 25 {
                newHobby = String(newHobby.prefix(25))
            }
        }
    }
    @State private var hobbies = ["Reading", "Running", "Swimming", "Painting", "Drawing", "Writing", "Gardening", "Cooking", "Baking", "Dancing", "Yoga", "Hiking", "Cycling", "Knitting", "Sewing", "Woodworking", "Photography", "Birdwatching", "Fishing", "Camping", "Rock Climbing", "Sky Diving", "Ice Skating", "Snowboarding", "Vegetarian", "Vegan", "Animal Lover"]

    var body: some View {
        ZStack {
            Color.vidaBackground
                .ignoresSafeArea()
            VStack {
                ScrollView {
                    Image("Pod Logomark")
                        .resizable()
                        .frame(maxWidth: 100, maxHeight: 100)
                        .padding(.bottom, 20)
                    LazyVStack {
                        ForEach(0..<30) { row in
                            HStack{
                                ForEach(0..<3) { column in
                                    let index = row * 3 + column
                                    if index < hobbies.count {
                                        HobbyButton(hobby: hobbies[index], isSelected: selectedHobbies.contains(hobbies[index])) {
                                            if selectedHobbies.contains(hobbies[index]) {
                                                selectedHobbies.removeAll(where: { $0 == hobbies[index] })
                                            } else {
                                                selectedHobbies.append(hobbies[index])
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        HStack {
                            TextField("", text: $newHobby)
                                .foregroundColor(.gray)
                                .accentColor(.gray)
                                .modifier(PlaceholderStyle(showPlaceHolder: newHobby.isEmpty,
                                                           placeholder: "Add Hobby"))
                            Button(action: {
                                if !newHobby.isEmpty {
                                    hobbies.append(newHobby)
                                    newHobby = ""
                                }
                            }) {
                                Text("Add")
                            }
                        }
                        .underlineTextField()
                        .padding(.vertical, 10)
                        
                        Button("Save") {
                            // Save the selected hobbies to Firestore here
                            // Replace the placeholder with your own Firestore collection and document names
                            let db = Firestore.firestore()
                            guard let userUid = Auth.auth().currentUser?.uid else { return }
                            let userRef = db.collection("users").document(userUid)
                            userRef.setData(["hobbies": selectedHobbies], merge: true){ error in
                                if let error = error {
                                    print("Error saving hobbies: \(error.localizedDescription)")
                                } else {
                                    navigateToPhotoUploadView = true
                                    showDetail.toggle()
                                }
                            }
                        }
                        .background(
                            NavigationLink(
                                destination:EmailLoginView(),
                                isActive: $navigateToPhotoUploadView,
                                label: {
                                    EmptyView()
                                })
                        )
                    }
                }
            }
            .padding()
        }
    }
}


struct PersonalityTraitsView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalityTraitsView()
    }
}

