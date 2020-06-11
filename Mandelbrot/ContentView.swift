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
    @EnvironmentObject var u:CalcFinish
    @State private var isSharePresented: Bool = false
    var body: some View{
        Button(action: {
            print("buttonPressed")
            self.isSharePresented = true
        }){
            Image(systemName: "square.and.arrow.up")
                .font(.title)
                .shadow(color: .white, radius: 1)
                .disabled(!u.flag)
                .padding()
        }
        .sheet(isPresented: $isSharePresented, onDismiss: {
            print("Dismiss")
        }, content: {
            ActivityViewController(activityItems: [UIImage(cgImage: lastImage!)])
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
    var body: some View {
        ZStack{
            TouchView()
                .edgesIgnoringSafeArea(.all)
            
            VStack{
                HStack{
                    XY0View()
                    Spacer()
                    Button(action: {}){
                        Image(systemName: "gear")
                            .font(.title)
                            .shadow(color: .white, radius: 1)
                            .padding()
                    }
                }
                Spacer()
                HStack{
                    ExportButton()
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
