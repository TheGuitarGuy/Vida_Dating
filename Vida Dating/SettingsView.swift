//
//  SettingsView.swift
//  Vida Dating
//
//  Created by Kennion Gubler on 10/22/23.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 54/255, green: 54/255, blue: 122/255)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                    
                    // Buttons for various settings categories
                    SettingsButton(title: "Account Settings", iconName: "person.fill")
                    SettingsButton(title: "Notifications", iconName: "bell.fill")
                    SettingsButton(title: "Appearance", iconName: "eyedropper.full")
                    SettingsButton(title: "Privacy and Security", iconName: "lock.fill")
                    SettingsButton(title: "Help and Support", iconName: "questionmark.circle.fill")
                    SettingsButton(title: "About", iconName: "info.circle.fill")
                    
                    Spacer()
                }
            }
        }
        .navigationBarTitle("", displayMode: .inline)
    }
}

struct SettingsButton: View {
    var title: String
    var iconName: String
    
    var body: some View {
        Button(action: {
            // Add action for the settings button
        }) {
            HStack {
                Text(title)
                    .padding(.leading)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.trailing)
            }
            .frame(height: 60)
            .background(
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white)
                        .opacity(0.3)
                        .padding(.horizontal)
                    Spacer()
                }
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
