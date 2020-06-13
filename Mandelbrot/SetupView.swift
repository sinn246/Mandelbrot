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
    var body: some View{
        VStack{
            Text("Faster-Than-Nanika Mandelbrot")
            Toggle(isOn: $cd.flag){
                Text("Use double-precision floating point")
            }
        }
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView()
    }
}
