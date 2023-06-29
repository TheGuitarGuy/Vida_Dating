//
//  MainView.swift
//  Gild_Dating
//
//  Created by Kennion Gubler on 4/11/23.
//

import SwiftUI

struct MainView: View {
    @State private var selection: Int = 0

    var body: some View {
        ZStack
        {
            TabView(selection: $selection) {
                HomeView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                    .tag(1)
                ConversationsView()
                    .tabItem {
                        Image(systemName: "message")
                        Text("Messages")
                    }
                    .tag(2)

                ProfileView()
                    .tabItem {
                        Image(systemName: "person")
                        Text("Profile")
                    }
                    .tag(3)
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

