

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import FirebaseStorage

struct EmailSignupView: View {
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var id = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignedUp = false
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var showingLogin = false
    
    var body: some View {
        NavigationStack
        {
            ZStack
            {
                Color(red: 54/255, green: 54/255, blue: 122/255)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Image("Pod Logomark")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 100)
                        .padding(.top, 25)
                        .padding(.bottom, 50)
                        .padding(.horizontal)
                    Text("Sign Up")
                        .font(.title)
                        .foregroundColor(.vidaWhite)
                    
                    HStack {
                        TextField("", text: $email)
                            .modifier(PlaceholderStyle(showPlaceHolder: email.isEmpty,
                                                       placeholder: "Email"))
                    }
                    .padding(.vertical)
                    .underlineTextField()
                    
                    
                    HStack {
                        SecureField("", text: $password)
                            .modifier(PlaceholderStyle(showPlaceHolder: password.isEmpty,
                                                       placeholder: "Password"))
                    }
                    .padding(.vertical)
                    .underlineTextField()
                    HStack {
                        SecureField("", text: $confirmPassword)
                            .modifier(PlaceholderStyle(showPlaceHolder: confirmPassword.isEmpty,
                                                       placeholder: "Confirm Password"))
                    }
                    .padding(.vertical)
                    .underlineTextField()
                    
                    Button(action: {
                        register()
                    }
                    ) {
                        Text("Sign Up")
                            .padding()
                            .padding(.horizontal, 30)
                            .foregroundColor(.vidaWhite)
                            .background(Color(red: 244/255, green: 11/255, blue: 114/255))
                            .cornerRadius(30)
                            .font(Font.system(size: 20))
                            .bold()
                    }
                    .padding(.bottom, 50)
                    .padding(.top, 50)
                    
                    NavigationLink(destination: BirthdayView(), isActive: $isSignedUp) {
                        EmptyView()
                    }
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.blue)
                        Button(action: {
                            showingLogin = true
                        }) {
                            Text("Sign In")
                                .foregroundColor(.vidaPink)
                        }
                        NavigationLink(destination: EmailLoginView(), isActive: $showingLogin) {
                            EmptyView()
                        }
                    }
                    .padding(.bottom, 15)
                }
                
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Sorry!"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }

        }
    }
    
    func register() {
        guard password == confirmPassword else {
            self.errorMessage = "Passwords do not match"
            showAlert = true
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                if let errorCode = AuthErrorCode.Code(rawValue: error.code) {
                    switch errorCode {
                    case .emailAlreadyInUse:
                        self.errorMessage = "Email address already in use"
                        showAlert = true

                    case .invalidEmail:
                        self.errorMessage = "Invalid email address"
                        showAlert = true
                    case .weakPassword:
                        self.errorMessage = "Password is too weak"
                        showAlert = true
                        
                    default:
                        print("Other error occurred: \(error.localizedDescription)")
                        print("Error domain: \(error.domain)")
                        print("Error code: \(error.code)")
                        print("User info: \(error.userInfo)")
                        showAlert = true
                    }
                }
            
                else {
                    print("Error registering user: \(error.localizedDescription)")
                    showAlert = true

                }
            }
            else {
                // User created successfully
                print("User registered successfully")

                // Save user data to Firestore
                let db = Firestore.firestore()
                if let userId = authResult?.user.uid {
                    let userDoc = db.collection("users").document(userId)
                    let userData = ["id": id, "email": email, "password": password]
                    userDoc.setData(userData) { error in
                        if let error = error {
                            print("Error saving user data: \(error.localizedDescription)")
                        } else {
                            print("User data saved successfully")
                            self.isSignedUp = true // Navigate to BirthdayView
                        }
                    }
                } else {
                    print("Error: authResult is nil")
                }
            }
        }
    }
}
extension Color {
    static let darkPink = Color(red: 208 / 255, green: 45 / 255, blue: 208 / 255)
    static let vidaWhite = Color(red: 243 / 255, green: 234 / 255, blue: 244 / 255)
    static let vidaBackground = Color(red: 54/255, green: 54/255, blue: 122/255)
    static let vidaPink = Color(red: 244/255, green: 11/255, blue: 114/255)
    static let vidaOrange = Color(red: 255/255, green: 186/255, blue: 83/255)
    static let vidaBlue = Color(red: 69/255, green: 105/255, blue: 144/255)
    
    
}
extension UIColor {
    static let darkPink = UIColor(red: 208 / 255, green: 45 / 255, blue: 208 / 255, alpha: 1.0)
    static let vidaWhite = UIColor(red: 243 / 255, green: 234 / 255, blue: 244 / 255, alpha: 1.0)
    static let vidaBackground = UIColor(red: 54/255, green: 54/255, blue: 122/255, alpha: 1.0)
    static let vidaPink = UIColor(red: 244/255, green: 11/255, blue: 114/255, alpha: 1.0)
    static let vidaOrange = UIColor(red: 255/255, green: 186/255, blue: 83/255, alpha: 1.0)
    static let vidaBlue = UIColor(red: 69/255, green: 105/255, blue: 144/255, alpha: 1.0)
}

extension View {
    func underlineTextField() -> some View {
        self
            .padding(.vertical, 10)
            .overlay(Rectangle().frame(height: 2).padding(.top, 35))
            .foregroundColor(.vidaWhite)
            .padding(.horizontal, 20)
            .accentColor(.vidaWhite)
    }
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
public struct PlaceholderStyle: ViewModifier {
    var showPlaceHolder: Bool
    var placeholder: String

    public func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            if showPlaceHolder {
                Text(placeholder)
                    .foregroundColor(Color.gray)
            }
            content
            .foregroundColor(Color.vidaWhite)
        }
    }
}
    struct EmailSignupView_Previews: PreviewProvider {
        static var previews: some View {
            EmailSignupView()
        }
    }



