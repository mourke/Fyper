//
//  DetailView.swift
//  Normal
//
//  Created by Mark Bourke on 18/03/2022.
//

import SwiftUI

struct DetailView: View {
    
    @State var viewModel: DetailViewModel
    
    @State private var presentingAlert: Bool = false
    
    var body: some View {
        Button("Authenticate") {
            presentingAlert.toggle()
            viewModel.authenticate()
        }
        .padding()
        .alert("Authenticated", isPresented: $presentingAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}
