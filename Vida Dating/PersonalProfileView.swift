//
//  PersonalProfileView.swift
//  Vida Dating
//
//  Created by Kennion Gubler on 5/2/23.
//

import SwiftUI

struct PersonalProfileView: View {
    let otherUserID: String
    
    var body: some View {
        Text("Personal profile for user with ID: \(otherUserID)")
    }
}

struct PersonalProfileView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalProfileView(otherUserID: "12345")
    }
}
