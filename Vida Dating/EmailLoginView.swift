//
//  LoginView.swift
//  Gild_Dating
//
//  Created by Kennion Gubler on 3/26/23.
//

import SwiftUI
import FirebaseAuth

struct EmailLoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordSecure: Bool = true
    @State private var isLoggedIn: Bool = false
    @State private var showingSignup = false
    
    var body: some View {
        ZStack{
            Color(red: 30/255, green: 30/255, blue: 60/255)
                .edgesIgnoringSafeArea(.all)
            VStack (spacing: 30){
                Spacer()
                Image("Vida_Logomark")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 100)
                    .padding(.horizontal)
                
                Text("Login")
                    .font(.largeTitle)
                    .foregroundColor(.vidaWhite)
                
                VStack {
                    TextField("Email", text: $email)
                        .modifier(PlaceholderStyle(showPlaceHolder: email.isEmpty,
                                                   placeholder: "Email"))
                        .underlineTextField()
                        .padding(.bottom, 30)
                    

                    SecureField("Password", text: $password)
                        .modifier(PlaceholderStyle(showPlaceHolder: password.isEmpty,
                                                   placeholder: "Password"))
                        .underlineTextField()
                }
                
                Button(action: {
                    loginUser(email: email, password: password) { result in
                        switch result {
                        case .success(let user):
                            print("Logged in successfully: \(user.uid)")
                            isLoggedIn = true
                        case .failure(let error):
                            print("Error logging in: \(error.localizedDescription)")
                            // TODO: Show error message to user
                        }
                    }
                }) {
                    Text("Login")
                        .padding()
                        .padding(.horizontal, 30)
                        .foregroundColor(.vidaWhite)
                        .background(Color(red: 244/255, green: 11/255, blue: 114/255))
                        .cornerRadius(30)
                        .font(Font.system(size: 20))
                        .bold()
                }
                .padding(.top, 20)
                NavigationLink(destination: MainView(), isActive: $isLoggedIn) {
                    EmptyView()
                }
                .padding(.horizontal)
                
                HStack {
                    Text("Need an account?")
                        .foregroundColor(.blue)
                    Button(action: {
                        showingSignup = true
                    }) {
                        Text("Sign Up")
                            .foregroundColor(.vidaPink)
                    }
                    NavigationLink(destination: SignupView(), isActive: $showingSignup) {
                        EmptyView()
                    }
                }
                Spacer()
            }
        }
        }
}


func loginUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
    Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let user = authResult?.user else {
            let error = NSError(domain: "Firebase", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
            completion(.failure(error))
            return
        }
        
        completion(.success(user))
    }
}

struct EmailLoginView_Previews: PreviewProvider {
    static var previews: some View {
        EmailLoginView()
    }
}
