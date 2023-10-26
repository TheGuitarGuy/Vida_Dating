import SwiftUI

struct SafetyView: View {
    var body: some View {
        ScrollView {
            VStack {
                Text("Dating Safety")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                
                Image("dating_safety_1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 20) {
                    SafetySection(title: "Meet in Public", imageName: "meet_public_icon", description: "Always meet your date in a public place, especially for the first few meetings. This ensures your safety and comfort.")
                    
                    SafetySection(title: "Tell a Friend", imageName: "tell_friend_icon", description: "Inform a trusted friend or family member about your date plans, including the location and time.")
                    
                    SafetySection(title: "Trust Your Instincts", imageName: "instinct_icon", description: "Listen to your gut feelings. If something feels off or uncomfortable, don't hesitate to leave the situation.")
                }
                .padding()
                .foregroundColor(.white)
                
                Spacer()
                
                EmergencyContactSection()
                
                Spacer()
            }
        }
        .background(Color(red: 54/255, green: 54/255, blue: 122/255).edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Safety", displayMode: .inline)
    }
}

struct SafetySection: View {
    var title: String
    var imageName: String
    var description: String
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: imageName)
                .font(.title)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(description)
                    .font(.subheadline)
                    .lineLimit(nil)
            }
        }
    }
}

struct EmergencyContactSection: View {
    var body: some View {
        VStack {
            Text("Emergency Contact")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
            
            Image("warning_image")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 20) {
                SafetySection(title: "Meet in Public", imageName: "meet_public_icon", description: "Always meet your date in a public place, especially for the first few meetings. This ensures your safety and comfort.")
                
                SafetySection(title: "Tell a Friend", imageName: "tell_friend_icon", description: "Inform a trusted friend or family member about your date plans, including the location and time.")
                
                SafetySection(title: "Trust Your Instincts", imageName: "instinct_icon", description: "Listen to your gut feelings. If something feels off or uncomfortable, don't hesitate to leave the situation.")
            }
            .padding()
            .foregroundColor(.white)
        }
    }
}

struct SafetyView_Previews: PreviewProvider {
    static var previews: some View {
        SafetyView()
    }
}
