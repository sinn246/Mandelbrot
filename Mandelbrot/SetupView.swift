//
//  SetupView.swift
//  Mandelbrot
//
//  Created by 西村 信一 on 2020/06/13.
//  Copyright © 2020 sinn246. All rights reserved.
//

import SwiftUI

struct SetupView: View {
    @EnvironmentObject var s:SetupVars
    @Binding var showSetup:Bool
    
    var body: some View{
        VStack(alignment: .center, spacing: 20){
            VStack(alignment: .center, spacing: 5){
                Text("Mandelbrot Set Explorer")
                    .bold()
                    .font(.title)
                    .foregroundColor(.blue)
                    .shadow(color: .purple, radius: 3)
                HStack{
                    Spacer()
                    Text("using Accelerate Framework")
                        .foregroundColor(.blue)
                        .italic()
                }
            }
            VStack(alignment: .center, spacing: 5){
                Toggle(isOn: $s.calcDouble){
                    Text("Use double-precision floating point")
                }
                Toggle(isOn: $s.calcZorder){
                    Text("Use Z-ordering display algorithm")
                }
                HStack{
                    Spacer()
                    Text("Turning on will take a little longer to compute")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            VStack(alignment: .center, spacing: 5){
                Text("Max Iteration")
                Picker(selection: $s.iterSel, label: Text("Iteration")) {
                    ForEach(0 ..< mas.iters.count) { num in
                        Text("\(mas.iters[num])")
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                HStack{
                    Spacer()
                    Text("Larger number will take longer to compute")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
            }
            VStack(alignment: .center, spacing: 5){
                Text("Coloring mode")
                Picker(selection: $s.colorSel, label: Text("Color")) {
                    ForEach(0 ..< mas.colorIters.count) { num in
                        Text(mas.colorIters[num])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                Text("Coloring base Hue")
                
                Slider(value: $s.colorHue, in: 0...1){_ in
                }
                .background(Image("Hue").resizable())
            }
            Button(action: {
                if mas.getClipboardData(reallyloadData: true){
                    self.showSetup = false
                }
            }){
                Text("Copy settings from clipboard").padding()
            }.disabled(!mas.isClipboardAvailable)
            Button(action: {
                mas.resetSetup()
                self.showSetup = false
            }){
                Text("Reset Settings").padding()
            }
        }.padding()
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView(showSetup: .constant(true))
            .environmentObject(mas.setupVars)
    }
}
