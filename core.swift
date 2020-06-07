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

final class Updater : ObservableObject {
    @Published var update:Bool = false
}
var updater:Updater = Updater()

