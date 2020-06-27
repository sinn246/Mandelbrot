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
    @Published var iterSel:Int  = 0
    @Published var colorSel:Int  = 2;
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
    
    var updater = Updater()
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
        UserDefaults.standard.set(setupVars.iterSel, forKey: "iterSel")
        UserDefaults.standard.set(setupVars.colorSel, forKey: "colorSel")
        UserDefaults.standard.set(setupVars.colorHue, forKey: "colorHue")
    }
    
    mutating func resetSetup(){
        setupVars.calcDouble = true
        setupVars.iterSel  = 0
        setupVars.colorSel  = 2
        setupVars.colorHue = 0.6
        X = 0
        Y = 0
        Scale = 1.0
    }
}

var mas:Global = Global()

@objcMembers class Bridge:NSObject {
    @objc class func setflag(_ f:Bool){
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

