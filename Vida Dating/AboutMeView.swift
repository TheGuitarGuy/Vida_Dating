//
//  AboutMeView.swift
//  Gild_Dating
//
//  Created by Kennion Gubler on 3/26/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct AboutMeView: View {
    @State private var bioText = ""
    @State private var characterCount = 0
    @State private var showDetail = false
    @State private var navigateToPersonalityTraitsView = false
    let db = Firestore.firestore()
    let user = Auth.auth().currentUser //Get the current user
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: Color.vidaBackground]
    }
    
    var body: some View {
        ZStack {
            Color(red: 30/255, green: 30/255, blue: 60/255)
                .ignoresSafeArea()
            
            VStack {
                Image("Vida_Logomark")
                    .resizable()
                    .frame(maxWidth: 100, maxHeight: 100)
                    .padding(.vertical, 20)
                Text("A fun fact about you:")
                    .foregroundColor(.vidaWhite)
                    .font(.title)
                    .padding(.vertical, 20)
                UITextViewWrapper(text: $bioText, characterCount: $characterCount)
                    .background(Color(red: 30/255, green: 30/255, blue: 60/255))
                    .multilineTextAlignment(.leading)
                    .frame(height: 200)
                    .padding(10)
                    .overlay(
                        Text("\(characterCount)/100")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 10))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing),
                        alignment: .bottomTrailing
                    )
                    .border(Color.white, width: 1)
                Button("Save") {
                    saveBioText()
                    navigateToPersonalityTraitsView = true
                    showDetail.toggle()
                }
                .background(
                    NavigationLink(
                        destination:PersonalityTraitsView(),
                        isActive: $navigateToPersonalityTraitsView,
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
                .padding()
                .padding(.horizontal, 10)
        }

        }
    
    func saveBioText() {
        guard let user = user else {
            print("Error: User is not logged in")
            return
        }
        
        // Generate a unique user ID
        let userID = UUID().uuidString
        
        // Set the data for the "name" field in the "users" collection
        let db = Firestore.firestore()
        guard let userUid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(userUid)
        userRef.setData(["bioText": bioText], merge: true){error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Document added with ID: \(user.uid)")
            }
        }
    }
}

struct UITextViewWrapper: UIViewRepresentable {
    @Binding var text: String
    @Binding var characterCount: Int
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.delegate = context.coordinator
        textView.textColor = UIColor.white
        textView.backgroundColor = UIColor(red: 30/255, green: 30/255, blue: 60/255, alpha: 1.0)
        textView.font = UIFont.systemFont(ofSize: 20)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        uiView.textAlignment = .left
        characterCount = uiView.text.count
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: UITextViewWrapper
        
        init(_ uiTextView: UITextViewWrapper) {
            self.parent = uiTextView
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text
            self.parent.characterCount = textView.text.count
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
            return newText.count <= 100
        }
    }
}

struct AboutMeView_Previews: PreviewProvider {
    static var previews: some View {
        AboutMeView()
    }
}
