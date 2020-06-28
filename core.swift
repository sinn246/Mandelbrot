//
//  core.swift
//  Mandelbrot
//
//  Created by 西村信一 on 2020/06/04.
//  Copyright © 2020 sinn246. All rights reserved.
//

import SwiftUI
import Combine

final class Updater : ObservableObject {
    @Published var flag:Bool = false
}

final class SetupVars : ObservableObject {
    @Published var calcDouble:Bool = true
    @Published var calcZorder:Bool = true
    @Published var iterSel:Int  = 0
    @Published var colorSel:Int  = 2
    @Published var colorHue:Double = 0.6
}

struct Global{
    var X:Double
    var Y:Double
    var WX:CGFloat = 480
    var WY:CGFloat = 640
    var Scale:Double
    
    var lastImage:CGImage? = nil
    var WZ:Int = 1000
    var calcTime:Double = 0.0
    
    var coordUpdater = Updater()
    var redrawer = Updater()
    var calcFinish = Updater()
    var setupVars = SetupVars()
    
    var pics:[(pic:MasPic,layer:CALayer)] = []
    var mainPic:MasPic? = nil
    
    let iters = [1000,3000,10000,30000]
    let colorIters = ["linear","log","mixed","RGB"]

    init() {
        X = UserDefaults.standard.double(forKey: "X")
        Y = UserDefaults.standard.double(forKey: "Y")
        if UserDefaults.standard.object(forKey: "Scale") != nil{
            Scale = UserDefaults.standard.double(forKey: "Scale")
        }else{
            Scale = 4.0 / 480.0
        }
        if UserDefaults.standard.object(forKey: "calcDouble") != nil{
            setupVars.calcDouble = UserDefaults.standard.bool(forKey: "calcDouble")
        }
        if UserDefaults.standard.object(forKey: "calcZorder") != nil{
            setupVars.calcZorder = UserDefaults.standard.bool(forKey: "calcZorder")
        }
        if UserDefaults.standard.object(forKey: "iterSel") != nil{
            setupVars.iterSel = UserDefaults.standard.integer(forKey: "iterSel")
            WZ = iters[setupVars.iterSel]
        }
        if UserDefaults.standard.object(forKey: "colorSel") != nil{
            setupVars.colorSel = UserDefaults.standard.integer(forKey: "colorSel")
        }
        if UserDefaults.standard.object(forKey: "colorHue") != nil{
            setupVars.colorHue = UserDefaults.standard.double(forKey: "colorHue")
        }
    }
    
    func saveCoord(){
        UserDefaults.standard.set(X, forKey: "X")
        UserDefaults.standard.set(Y, forKey: "Y")
        UserDefaults.standard.set(Scale, forKey: "Scale")
    }
    
    func saveSettings(){
        UserDefaults.standard.set(setupVars.calcDouble, forKey: "calcDouble")
        UserDefaults.standard.set(setupVars.calcZorder, forKey: "calcZorder")
        UserDefaults.standard.set(setupVars.iterSel, forKey: "iterSel")
        UserDefaults.standard.set(setupVars.colorSel, forKey: "colorSel")
        UserDefaults.standard.set(setupVars.colorHue, forKey: "colorHue")
    }
    
    mutating func resetSetup(){
        setupVars.calcDouble = true
        setupVars.calcZorder = true
        setupVars.iterSel  = 0
        setupVars.colorSel  = 2
        setupVars.colorHue = 0.6
        X = 0
        Y = 0
        Scale = 1.0
    }
    

    struct JSONformat: Codable{
        var X:Double
        var Y:Double
        var WX:Double
        var WY:Double
        var Z:Int
    }

    func JSONexport()->String{
        let out = JSONformat(X: X, Y: Y, WX: Double(WX)*Scale, WY: Double(WY)*Scale, Z: WZ)
        do{
            let data = try JSONEncoder().encode(out)
            if let s = String(data: data, encoding: .utf8){
                return s
            }
        }catch{
            print("JSON Encode failed??")
        }
        return ""
    }
    
    var isClipboardAvailable:Bool {
        get{
            if UIPasteboard.general.string != nil{
                return getClipboardData(reallyloadData: false)
            }
            return false
        }
    }
    
    func getClipboardData(reallyloadData:Bool)->Bool{
        guard let s = UIPasteboard.general.string else{
            return false
        }
        do{
            let data = try JSONDecoder().decode(JSONformat.self, from: s.data(using: .utf8)!)
            if !reallyloadData {return true}
            mas.X = data.X
            mas.Y = data.Y
            mas.WZ = data.Z
            for i in 0..<iters.count{
                if iters[i] >= data.Z{
                    setupVars.iterSel = i
                    mas.WZ = iters[i]
                    break
                }
            }
            mas.Scale = min(data.WX / Double(WX),data.WY / Double(WY))
        }catch{
            return false
        }
        return true
    }
}

var mas:Global = Global()


@objcMembers class Bridge:NSObject {
    @objc class func calcStartStop(_ f:Bool,time:Double){
        mas.calcTime = time
        DispatchQueue.main.async {
            mas.calcFinish.flag = f
        }
    }
    @objc class func setLastImage(_ img:CGImage){
        mas.lastImage = img
    }
    @objc class func getColorMode()->Int{
        return mas.setupVars.colorSel
    }
    @objc class func getColorHue()->Double{
        return mas.setupVars.colorHue
    }
}
