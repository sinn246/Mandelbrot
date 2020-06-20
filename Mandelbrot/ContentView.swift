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
            .foregroundColor(.white)
            .shadow(color: .black, radius: 1)
    }
}

struct XY1View: View{
    @EnvironmentObject var u:Updater
    var body: some View{
        Text("(\(mas.X+mas.Scale*Double(mas.WX)/2),\(mas.Y-mas.Scale*Double(mas.WY)/2))")
            .foregroundColor(.white)
            .shadow(color: .black, radius: 1)
    }
}

struct ExportButton: View{
    @EnvironmentObject var calcFinish:Updater
    @State private var isSharePresented: Bool = false
    var body: some View{
        Button(action: {
            print("buttonPressed")
            self.isSharePresented = true
        }){
            Image(systemName: "square.and.arrow.up")
                .font(.title)
                .shadow(color: (calcFinish.flag ? .white : .black), radius: 1)
                .disabled(!calcFinish.flag)
                .padding()
        }.disabled(!calcFinish.flag)
        .sheet(isPresented: $isSharePresented, onDismiss: {
            print("Dismiss")
        }, content: {
            ActivityViewController(activityItems: [UIImage(cgImage: mas.lastImage!)])
        })
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

////////////////////////////


struct ContentView: View {
    @State var setup = false
    var body: some View {
        ZStack{
            TouchView()
                .environmentObject(mas.redrawer)
                .edgesIgnoringSafeArea(.all)
            
            VStack{
                HStack{
                    XY0View()
                    Spacer()
                    Button(action: {
                        self.setup.toggle()
                    }){
                        Image(systemName: "gear")
                            .font(.title)
                            .shadow(color: .white, radius: 1)
                            .padding()
                    }
                    .sheet(isPresented: $setup,
                           onDismiss: {
                            mas.WZ = mas.iters[mas.setupVars.iterSel]
                            print("Iter = \(mas.WZ)")
                            mas.redrawer.flag.toggle()
                    },
                           content: {
                            SetupView()
                                .environmentObject(mas.setupVars)
                    })
                }
                Spacer()
                HStack{
                    ExportButton()
                        .environmentObject(mas.calcFinish)
                    Spacer()
                    XY1View()
                }
            }.padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
