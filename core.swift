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
    @Published var colorSel:Int  = 0;
}

struct Global{
    var X:Double = 0
    var Y:Double = 0
    var WX:CGFloat = 480
    var WY:CGFloat = 640
    var Scale:Double = 4.0 / 480.0

    var lastImage:CGImage? = nil
    var WZ:Int = 1000

    var updater = Updater()
    var redrawer = Updater()
    var calcFinish = Updater()
    var setupVars = SetupVars()
    
    var pics:[(pic:MasPic,layer:CALayer)] = []
    var mainPic:MasPic? = nil
    
    let iters = [1000,3000,10000,30000]
    let colorIters = ["log","linear","??"]
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

}
