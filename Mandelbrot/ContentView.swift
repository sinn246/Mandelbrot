//
//  ContentView.swift
//  Mandelbrot
//
//  Created by 西村信一 on 2020/06/04.
//  Copyright © 2020 sinn246. All rights reserved.
//

import SwiftUI

// UI parts in ContentView

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
                ActivityViewController(activityItems: [UIImage(cgImage: mas.lastImage!), mas.JSONexport()])
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



struct TimeDisplayer: View{
    @EnvironmentObject var showTime:Updater
    @State var timer:Timer? = nil

    var body: some View{
        Text(mas.calcTime > 0 ? "\(mas.calcTime) sec" : "")
            .italic()
            .bold()
            .font(.title)
            .foregroundColor(.white)
            .shadow(color: .black, radius: 1)
            .animation(.easeIn)
            .transition(.slide)
            .onAppear {
                // 画面変更連打やスリープその他の理由でタイマーが呼ばれすぎたり呼ばれなかったり
                // したとき画面が残るバグが発生
                // repeatsをtrueにして手動でタイマーをinvalidateしたらうまく動くように
                print("TimeDisplayer:onAppear")
                self.timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true){ timer in
                    self.showTime.flag = false
                }
            
            }
            .onDisappear(){
                print("TimeDisplayer:onDisappear")
                self.timer?.invalidate()
            }
    }
}

// ContentView itself

struct ContentView: View {
    @State var showSetup = false
    @EnvironmentObject var showTime:Updater
    var body: some View {
        ZStack{
            // First layer
            TouchView().environmentObject(mas.redrawer)
                .edgesIgnoringSafeArea(.all)
            
            // Second layer
            VStack{
                HStack{
                    XY0View().environmentObject(mas.coordUpdater)
                    Spacer()
                    Button(action: {
                        self.showSetup = true
                    }){
                        Image(systemName: "gear")
                            .font(.title)
                            .shadow(color: .white, radius: 1)
                            .padding()
                    }
                    .sheet(isPresented: $showSetup,
                           onDismiss: {
                            mas.WZ = mas.iters[mas.setupVars.iterSel]
                            print("Iter = \(mas.WZ)")
                            mas.redrawer.flag.toggle()
                            mas.saveSettings()
                    },
                           content: {
                            SetupView(showSetup: self.$showSetup).environmentObject(mas.setupVars)
                    })
                }
                Spacer()
                HStack{
                    Spacer()
                    if showTime.flag {
                        TimeDisplayer().environmentObject(mas.showTime)
                    }
                }
                HStack{
                    ExportButton().environmentObject(mas.calcFinish)
                    Spacer()
                    XY1View().environmentObject(mas.coordUpdater)
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
