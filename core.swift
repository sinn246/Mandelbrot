//
//  core.swift
//  Mandelbrot
//
//  Created by 西村信一 on 2020/06/04.
//  Copyright © 2020 sinn246. All rights reserved.
//

import SwiftUI
import Combine

struct Global{
    var X:Double = 0
    var Y:Double = 0
    var WX:CGFloat = 480
    var WY:CGFloat = 640
    var Scale:Double = 4.0 / 480.0
}

var mas:Global = Global()
var lastImage:CGImage? = nil

final class Updater : ObservableObject {
    @Published var flag:Bool = false
}
var updater:Updater = Updater()

final class CalcFinish : ObservableObject {
    @Published var flag:Bool = false
}
var calcFinish = CalcFinish()

@objcMembers class Bridge:NSObject {
    @objc class func setflag(_ f:Bool){
        DispatchQueue.main.async {
            calcFinish.flag = f
        }
    }
    @objc class func setLastImage(_ img:CGImage){
        lastImage = img
    }

}
