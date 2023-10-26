import SwiftUI

struct YouMatchedView: View {
    let dismissAction: () -> Void
    let vidaPink = Color(red: 244/255, green: 11/255, blue: 114/255)
    let vidaOrange = Color(red: 255/255, green: 186/255, blue: 83/255)
    let vidaBlue = Color(red: 69/255, green: 105/255, blue: 144/255)
    
    var body: some View {
        
        ZStack {
            LinearGradient(gradient: Gradient(colors: [vidaPink, vidaOrange]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "xmark.circle.fill") // "X" icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                        .onTapGesture {
                            // Call the dismiss action when "X" is tapped
                            dismissAction()
                        }
                        .padding(.trailing, 20) // Add some padding
                        .padding(.top, 20) // Add top padding to "X" button
                }
                
                Spacer() // Push content to the vertical center
                
                Text("It's a match!💖")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity) // Center the title horizontally

                Text("Maybe you two should talk...")
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                Spacer() // Push the "X" button to the vertical center
            }
            .padding()
        }
    }
}
