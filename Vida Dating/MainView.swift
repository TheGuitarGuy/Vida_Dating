import SwiftUI

struct MainView: View {
    @State private var selection: Int = 0

    init() {
        let appearance = UITabBarAppearance()
        
        appearance.stackedLayoutAppearance.normal.iconColor = .vidaWhite // For unselected state
        appearance.stackedLayoutAppearance.selected.iconColor = .vidaPink // For selected state
        
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.vidaWhite] // For unselected state
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.vidaPink] // For selected state
        
        appearance.backgroundColor = UIColor.vidaBackground
        
        UITabBar.appearance().standardAppearance = appearance
    }

    
    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .navigationBarTitle("")
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
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
            MatchesView().navigationBarBackButtonHidden(true)
                .tabItem{
                    Image(systemName: "heart.fill")
                    Text("Matches")
                }
                .tag(3)
            ProfileView().navigationBarBackButtonHidden(true)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(4)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
