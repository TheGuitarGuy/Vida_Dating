//
//  NameView.swift
//  Gild_Dating
//
//  Created by Kennion Gubler on 3/26/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct NameView: View {
    @State private var firstName = ""
    @State private var navigateToPhotoUploadView = false
    @State private var showDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 30/255, green: 30/255, blue: 60/255)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Text("Enter your First Name:")
                        .font(.title)
                        .padding()
                        .foregroundColor(.white)
                    
                    HStack {
                        TextField("", text: $firstName)
                            .modifier(PlaceholderStyle(showPlaceHolder: firstName.isEmpty,
                                                       placeholder: "First Name:"))
                    }
                    .padding(.vertical)
                    .underlineTextField()
                    
                    Button("Continue") {
                        // Create a reference to the Firestore database
                        let db = Firestore.firestore()
                        guard let userUid = Auth.auth().currentUser?.uid else { return }
                        let userRef = db.collection("users").document(userUid)
                        userRef.setData(["name": firstName], merge: true)
                        
                        navigateToPhotoUploadView = true
                        showDetail.toggle()
                    }
                    .background(
                        NavigationLink(
                            destination: AboutMeView(),
                            isActive: $navigateToPhotoUploadView,
                            label: {
                                EmptyView()
                            })
                    )
                    .padding()
                    .padding(.horizontal, 30)
                    .foregroundColor(.vidaWhite)
                    .background(Color(red: 244/255, green: 11/255, blue: 114/255))
                    .cornerRadius(30)
                    .font(Font.system(size: 20))
                    .bold()
                    .cornerRadius(10)
                    .padding(.vertical)
                }
            }
        }
    }
}


struct NameView_Previews: PreviewProvider {
    static var previews: some View {
        NameView()
    }
}


