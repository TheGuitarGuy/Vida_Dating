//
//  Launch.swift
//  Vida Dating
//
//  Created by Kennion Gubler on 5/7/23.
//


import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        Image("vida animation")
            .resizable()
            .scaledToFit()
            .animation(Animation.default.repeatForever())
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        // Start the animation
                    }
                }
            }
    }
}


struct Launch_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreen()
    }
}
