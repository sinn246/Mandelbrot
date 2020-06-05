//
//  ContentView.swift
//  Mandelbrot
//
//  Created by 西村信一 on 2020/06/04.
//  Copyright © 2020 sinn246. All rights reserved.
//

import SwiftUI


struct XY0View: View{
    @EnvironmentObject var m:Mandel
    var body: some View{
        Text("(\(m.X-m.Scale*Double(m.WX)/2),\(m.Y+m.Scale*Double(m.WY)/2))")
    }
}

struct XY1View: View{
    @EnvironmentObject var m:Mandel
    var body: some View{
        Text("(\(m.X+m.Scale*Double(m.WX)/2),\(m.Y-m.Scale*Double(m.WY)/2))")
    }
}

struct ContentView: View {
    @EnvironmentObject var m:Mandel
//    @State private var imageUpdated:Bool = false
    var body: some View {
        ZStack{
            GeometryReader{ geo -> TouchView in
                print("******", geo.size)
                self.m.WX = geo.size.width
                self.m.WY = geo.size.height
                return(TouchView())
            }
            VStack{
                HStack{
                    XY0View()
                    Spacer()
                    Button(action: {}){
                        Image(systemName: "gear")
                            .font(.title)
                    }
                }
                Spacer()
                HStack{
                    Button(action: {}){
                        Image(systemName: "gear")
                            .font(.title)
                    }
                    Spacer()
                    XY1View()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
