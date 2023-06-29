//
//  BithdayView.swift
//  Gild_Dating
//
//  Created by Kennion Gubler on 3/26/23.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore

struct BirthdayView: View {
    @State private var birthdate = Date()
    @State private var showAlert = false
    @State private var navigateToNameView = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 30/255, green: 30/255, blue: 60/255)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Image("Vida_Logomark")
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
                            navigateToNameView = true
                            setAgeInFirestore(age: age) // Add this line
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
                    destination: NameView(),
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
    
    private func setAgeInFirestore(age: Int) { // Add this method
        guard let userUid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(userUid)
        userRef.setData(["age": age], merge: true)
    }
}


struct BirthdayView_Previews: PreviewProvider {
    static var previews: some View {
        BirthdayView()
    }
}
