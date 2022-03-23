//
//  MasterView.swift
//  Normal
//
//  Created by Mark Bourke on 18/03/2022.
//

import SwiftUI

struct MasterView: View {
    
    @State var viewModel: MasterViewModel
    
    @State private var showDetail: Bool = false
    
    var body: some View {
        Button(viewModel.buttonTitle) {
            showDetail.toggle()
        }
        .padding()
        .onAppear {
            viewModel.track()
        }
        .popover(isPresented: $showDetail) {
            DetailView(viewModel: viewModel.detailViewModel())
        }
        
    }
}
