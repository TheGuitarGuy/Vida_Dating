//
//  SignupView.swift
//  Vida Dating
//
//  Created by Kennion Gubler on 6/24/23.
//
import SwiftUI
import AuthenticationServices
import FirebaseAuth
import CryptoKit

// Define the navigation targets
enum NavigationTarget {
    case main
    case birthday
    case emailLogin
    case none
}

struct SignupView: View {
    @State private var currentNonce: String?
    @State private var navigateToView: NavigationTarget = .none
    @State private var showMain = false
    @State private var showBirthday = false
    @State private var showEmailLogin = false

    var body: some View {
        NavigationStack {
            ZStack{
                Color(red: 54/255, green: 54/255, blue: 122/255)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Image("Pod_Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 500)
                        .padding(.top, 25)
                        .padding(.bottom, 50)
                        .padding(.horizontal)

                    NavigationLink(destination: MainView()
                                    .navigationBarBackButtonHidden(true), // Add this modifier
                                   isActive: $showMain) {
                        EmptyView()
                    }

                    NavigationLink(destination: BirthdayView()
                                    .navigationBarBackButtonHidden(true), // Add this modifier
                                   isActive: $showBirthday) {
                        EmptyView()
                    }

                    NavigationLink(destination: EmailLoginView()
                                    .navigationBarBackButtonHidden(true), // Add this modifier
                                   isActive: $showEmailLogin) {
                        EmptyView()
                    }


                    SignInWithAppleButton(.signIn, onRequest: { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.nonce = sha256(nonce)
                    }, onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                                return
                            }
                            guard let nonce = currentNonce else {
                                print("Invalid state: A login callback was received, but no login request was sent.")
                                return
                            }
                            guard let appleIDToken = appleIDCredential.identityToken else {
                                print("Unable to fetch identity token")
                                return
                            }
                            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                                return
                            }

                            let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
                            Auth.auth().signIn(with: firebaseCredential) { (authResult, error) in
                                DispatchQueue.main.async {
                                    if let error = error {
                                        print(error.localizedDescription)
                                        return
                                    }

                                    if let isNewUser = authResult?.additionalUserInfo?.isNewUser {
                                        if isNewUser {
                                            print("Navigating to Birthday View")
                                            self.navigateToView = .birthday
                                            self.showBirthday = true
                                        } else {
                                            print("Navigating to Main View")
                                            self.navigateToView = .main
                                            self.showMain = true
                                        }
                                    }
                                }
                            }
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                    })
                    .signInWithAppleButtonStyle(.white)
                    .frame(width: 280, height: 45, alignment: .center)
                    
                    Button("Continue with Facebook") {
                        self.navigateToView = .emailLogin
                        self.showEmailLogin = true
                    }
                    .foregroundColor(.white)
                    .frame(width: 280, height: 45, alignment: .center)
                    .background(Color.blue)
                    .cornerRadius(7.5)
                    .fontWeight(.bold)
                    
                    Button("Continue with Email") {
                        self.navigateToView = .emailLogin
                        self.showEmailLogin = true
                    }
                    .foregroundColor(.white)
                    .frame(width: 280, height: 45, alignment: .center)
                    .background(Color.black)
                    .cornerRadius(7.5)
                    .fontWeight(.bold)
                    
                }
                .padding(.bottom, 100)
            }
        }
    }

    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
