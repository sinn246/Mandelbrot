//
//  ContentView.swift
//  Mandelbrot
//
//  Created by 西村信一 on 2020/06/04.
//  Copyright © 2020 sinn246. All rights reserved.
//

import SwiftUI


struct XY0View: View{
    @EnvironmentObject var u:Updater
    var body: some View{
        Text("(\(mas.X-mas.Scale*Double(mas.WX)/2),\(mas.Y+mas.Scale*Double(mas.WY)/2))")
    }
}

struct XY1View: View{
    @EnvironmentObject var u:Updater
    var body: some View{
        Text("(\(mas.X+mas.Scale*Double(mas.WX)/2),\(mas.Y-mas.Scale*Double(mas.WY)/2))")
    }
}

struct ContentView: View {
    var body: some View {
        ZStack{
            GeometryReader{ geo -> TouchView in
                print("******", geo.size)
                mas.WX = geo.size.width
                mas.WY = geo.size.height
                let tv = TouchView()
                return(tv)
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
