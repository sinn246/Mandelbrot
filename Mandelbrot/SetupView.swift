//
//  SetupView.swift
//  Mandelbrot
//
//  Created by 西村 信一 on 2020/06/13.
//  Copyright © 2020 sinn246. All rights reserved.
//

import SwiftUI

struct SetupView: View {
    @EnvironmentObject var cd:CalcDouble
    @EnvironmentObject var ci:CalcIter
    @EnvironmentObject var oi:ColorIter

    var body: some View{
        VStack{
            Text("Faster-Than-Nanika Mandelbrot")
            Toggle(isOn: $cd.flag){
                Text("Use double-precision floating point")
                
            }
            Picker(selection: $ci.selected, label: Text("Iteration")) {
                ForEach(0 ..< mas.iters.count) { num in
                    Text("\(mas.iters[num])")
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            Picker(selection: $oi.selected, label: Text("Color")) {
                ForEach(0 ..< mas.colorIters.count) { num in
                    Text("\(mas.colorIters[num])")
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView()
    }
}
