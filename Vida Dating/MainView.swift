import SwiftUI

struct MainView: View {
    @State private var selection: Int = 0

    init() {
        let appearance = UITabBarAppearance()
        
        appearance.stackedLayoutAppearance.normal.iconColor = .vidaPink // For unselected state
        appearance.stackedLayoutAppearance.selected.iconColor = .vidaOrange // For selected state
        
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.vidaPink] // For unselected state
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.vidaOrange] // For selected state
        
        UITabBar.appearance().standardAppearance = appearance
    }

    
    var body: some View {
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

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
