//
//  TabBar.swift
//  SkyCast
//
//  Created by pooja kamble on 15/07/26.
//

import SwiftUI

struct TabBar: View {
    var action : () -> Void
    
    var body: some View {
        ZStack {
            Arc()
                .fill(Color.tabBarBackground)
                .frame(height: 88)
                .overlay {
                    Arc()
                        .stroke(Color.apptabBarBorder,lineWidth: 0.5)
                }
            HStack {
                Button {
                    action()
                } label: {
                    Image(systemName: "mappin.and.ellipse")
                        .frame(width: 44,height: 44)
                }
                Spacer()
                
                
            }
        }
    }
}

