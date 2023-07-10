//
//  Vida_DatingApp.swift
//  Vida Dating
//
//  Created by Kennion Gubler on 4/19/23.
//

import SwiftUI
import Firebase
import FirebaseStorage
import UIKit

@main
struct Vida_DatingApp: App {
    init() {
        FirebaseApp.configure()
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    var body: some Scene {
        WindowGroup {
            SignupView()
        }
    }
}
