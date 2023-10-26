//
//  BirthdayView.swift
//  Gild_Dating
//
//  Created by Kennion Gubler on 3/26/23.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI

struct BirthdayView: View {
    @State private var birthdate = Date()
    @State private var showAlert = false
    @State private var navigateToNameView = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 54/255, green: 54/255, blue: 122/255)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Image("Pod Logomark")
                        .resizable()
                        .scaledToFit()
                        .padding(.top, 50)
                        .padding(.bottom, 20)
                        .frame(maxWidth: 100)
                    Text("Enter your birthday:")
                        .font(.title)
                        .padding()
                        .foregroundColor(.white)
                    
                    DatePicker(
                        "Birthday",
                        selection: $birthdate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .colorScheme(.dark)
                    .labelsHidden()
                    .padding()
                    Button(action: {
                        let age = getAge(from: birthdate)
                        if age < 18 {
                            showAlert = true
                        } else {
                            // Set the default image for the user
                            setDefaultImageForCurrentUser()
                            
                            navigateToNameView = true
                            setAgeInFirestore(age: age)
                        }
                    }) {
                        Text("Continue")
                            .padding()
                            .padding(.horizontal, 30)
                            .foregroundColor(.white)
                            .background(Color(red: 244/255, green: 11/255, blue: 114/255))
                            .cornerRadius(30)
                            .font(Font.system(size: 20))
                            .bold()
                    }
                    .padding(.bottom, 50)
                    .padding(.top, 50)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Sorry!"),
                    message: Text("You have to be 18 or older to use this app!"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .background(
                NavigationLink(
                    destination: NameView().navigationBarBackButtonHidden(true),
                    isActive: $navigateToNameView,
                    label: {
                        EmptyView()
                    })
            )
        }
    }
    
    private func getAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date, to: Date())
        return components.year ?? 0
    }
    
    private func setAgeInFirestore(age: Int) {
        guard let userUid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(userUid)
        userRef.setData(["age": age], merge: true)
    }

    private func setDefaultImageForCurrentUser() {
        if let user = Auth.auth().currentUser {
            // Replace with the actual URL of your default image in Firebase Storage
            let defaultImageURL = "https://firebasestorage.googleapis.com/v0/b/vida-dating.appspot.com/o/default_image.png?alt=media&token=b2d37dd9-47f6-41f8-b071-54b4809d592b&_gl=1*15er7k5*_ga*MTM0MjM0MzMwMy4xNjk3ODIzNDk5*_ga_CW55HF8NVT*MTY5ODIwMzIwMS4xMy4xLjE2OTgyMDM2NTIuMzQuMC4w"

            // Update Firestore document to add the default image URL to the photoURLs array
            if let userUid = Auth.auth().currentUser?.uid {
                let userRef = db.collection("users").document(userUid)
                
                // Fetch the existing photoURLs array from Firestore
                userRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        if var photoURLs = document.data()?["photoURLs"] as? [String] {
                            // Add the default image URL to the beginning of the array
                            photoURLs.insert(defaultImageURL, at: 0)
                            
                            // Update the Firestore document with the updated photoURLs array
                            userRef.setData(["photoURLs": photoURLs], merge: true) { error in
                                if let error = error {
                                    print("Error updating Firestore document: \(error.localizedDescription)")
                                } else {
                                    print("Default image URL added to photoURLs array successfully")
                                }
                            }
                        } else {
                            // If there are no existing photoURLs, create a new array with the default URL
                            let photoURLs = [defaultImageURL]
                            userRef.setData(["photoURLs": photoURLs], merge: true) { error in
                                if let error = error {
                                    print("Error updating Firestore document: \(error.localizedDescription)")
                                } else {
                                    print("Default image URL added to photoURLs array successfully")
                                }
                            }
                        }
                    } else {
                        print("User document not found.")
                    }
                }
            }
        }
    }
}


struct BirthdayView_Previews: PreviewProvider {
    static var previews: some View {
        BirthdayView()
    }
}
