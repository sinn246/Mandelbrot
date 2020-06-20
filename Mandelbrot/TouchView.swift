//
//  TouchView.swift
//  Mandelbrot
//
//  Created by 西村信一 on 2020/06/04.
//  Copyright © 2020 sinn246. All rights reserved.
//

import SwiftUI
import UIKit

let maxLoop:Int = 10000
let startLoop:Int = 100

class MasPic {
    var X0,Y0,X1,Y1:Double
    var Scale:Double
    var WX,WY:Int
    var image:CGImage? = nil
    var stop:Bool = false
    var upd:(MasPic)->()
    var pid = 0
    init(x:Double,y:Double,scale:Double,wx:CGFloat,wy:CGFloat,update:@escaping (MasPic)->()){
        X0 = x - Double(wx) / 2 * scale
        Y0 = y + Double(wy) / 2 * scale
        X1 = x + Double(wx) / 2 * scale
        Y1 = y - Double(wy) / 2 * scale
        let s = UIScreen.main.scale // Retina display scale is encapsulated in this class
        Scale = scale / Double(s)
        WX = Int(wx * s)
        WY = Int(wy * s)
        upd = update
    }
    convenience init(update:@escaping (MasPic)->()){
        self.init(x:mas.X,y:mas.Y,scale:mas.Scale,wx:mas.WX,wy:mas.WY,update:update)
    }
    
    func calc(WZ:Int){
        pid+=1
        let my_pid = pid
        let block = {(_ img:CGImage?) -> Bool in
            if !self.stop && self.pid == my_pid{
                self.image = img
                self.upd(self)
                return false
            }
            return true
        }
        DispatchQueue.global(qos: .default).async {
            if mas.setupVars.calcDouble{
                calc_masD(self.WX,self.WY,WZ,self.X0,self.Y0,self.Scale,block)
            }else{
                calc_mas(self.WX,self.WY,WZ,self.X0,self.Y0,self.Scale,block)
            }
        }
    }
}

class ZoomView: UIView {
    
    enum CanvasTouchState{
        case
        NoTouch,
        FirstTouch,
        Dragging,
        SecondTouch,
        Zooming,
        TooManyTouches
    }
    var presentState:CanvasTouchState = .NoTouch
    var timeInitial:TimeInterval = 0
    
    /// const
    var Scale_MAX:Double = 8.0
    var Scale_MIN:Double = 1.0
    
    var mainLayer = CALayer()
    var initialstate:Bool = true
    
    init(){
        super.init(frame:CGRect.null)
    }
    /*    required override init(frame F: CGRect) {
     super.init(frame:F)
     }
     */
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        if(mas.WX == bounds.width && mas.WY == bounds.height){
            print("redundant layoutsubviews:\(self.bounds)")
        }else{
            print("layoutsubviews:\(self.bounds)")
            mas.WX = bounds.width
            mas.WY = bounds.height
            SizeChanged()
        }
    }
    
    func SizeChanged(){
        Scale_MAX = 4.0 / Double(min(mas.WX,mas.WY))
        Scale_MIN = Double.ulpOfOne * 100
        for l in mas.pics{
            l.layer.removeFromSuperlayer()
            l.pic.stop = true
        }
        mas.pics = []
        
        mas.mainPic = MasPic(x: 0, y: 0, scale: Scale_MAX, wx: mas.WX, wy: mas.WY, update: {mp in
            DispatchQueue.main.async {
                self.mainLayer.contents = mp.image!
                self.setNeedsDisplay()
            }
        })
        mas.mainPic?.calc(WZ: startLoop)
        
        mainLayer.frame = UIRect(from: mas.mainPic!)
        layer.addSublayer(mainLayer)
        
        if initialstate{
            mas.Scale = Scale_MAX
        }
        updateFrame(finish: true, scale: mas.Scale)
    }
    
    
    func UIRect(from:MasPic)->CGRect{
        let p0 = Pic2UI(CGPoint(x:from.X0,y:from.Y0))
        let p1 = Pic2UI(CGPoint(x:from.X1,y:from.Y1))
        return(CGRect(origin: p0,
                      size: CGSize(width: p1.x - p0.x, height: p1.y - p0.y)))
    }
    
    func UI2Pic(_ point:CGPoint)->CGPoint{
        return CGPoint(
            x: mas.X + (Double(point.x) - Double(mas.WX)/2.0) * mas.Scale,
            y: mas.Y - (Double(point.y) - Double(mas.WY)/2.0) * mas.Scale
        )
    }
    func Pic2UI(_ point:CGPoint)->CGPoint{
        return CGPoint(
            x: (Double(point.x) - mas.X) / mas.Scale + Double(mas.WX) / 2.0 ,
            y: -(Double(point.y) - mas.Y) / mas.Scale + Double(mas.WY) / 2.0
        )
    }
    
    var scaleBeforeMove:Double = 1.0
    var D2_start:CGFloat = 0;
    var UIcenter_start:CGPoint = CGPoint()
    var PICcenter_start:CGPoint = CGPoint()
    var X_start:Double = 0
    var Y_start:Double = 0
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let nTouch = event?.allTouches?.count
        if nTouch == 1{
            presentState = .FirstTouch
        }else if nTouch == 2{
            presentState = .SecondTouch
        }else {
            presentState = .TooManyTouches
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let nTouch = event?.allTouches?.count
        if nTouch == 1 {
            let t1 = event!.allTouches!.first!
            if presentState != .Dragging{
                presentState = .Dragging
                scaleBeforeMove = mas.Scale
                UIcenter_start = t1.previousLocation(in: self)
                X_start = mas.X
                Y_start = mas.Y
            }
            let p = t1.location(in: self)
            mas.X = X_start + Double(UIcenter_start.x - p.x) * mas.Scale
            mas.Y = Y_start - Double(UIcenter_start.y - p.y) * mas.Scale
            updateFrame(finish:false,scale:mas.Scale)
            
        }else if nTouch == 2{
            let arr = Array(event!.allTouches!)
            if presentState != .Zooming{
                presentState = .Zooming
                scaleBeforeMove = mas.Scale
                let p1 = arr[0].previousLocation(in: self)
                let p2 = arr[1].previousLocation(in: self)
                D2_start = (p1.x - p2.x)*(p1.x - p2.x) + (p1.y - p2.y)*(p1.y - p2.y)
                UIcenter_start = CGPoint(x:Double(p1.x + p2.x)/2, y: Double(p1.y + p2.y)/2)
                PICcenter_start = UI2Pic(UIcenter_start)
            }
            let p0 = arr[0].location(in: self)
            let p1 = arr[1].location(in: self)
            let D2:CGFloat = (p1.x-p0.x)*(p1.x-p0.x) + (p1.y-p0.y)*(p1.y-p0.y)
            let center:CGPoint = CGPoint(x:(p1.x+p0.x)/CGFloat(2),y:(p1.y+p0.y)/CGFloat(2))
            var factor = Double(D2_start / D2);
            var scale = scaleBeforeMove * factor
            if scale < Scale_MIN { scale = Scale_MIN }
            if scale > Scale_MAX { scale = Scale_MAX }
            factor = scale / scaleBeforeMove
            let dx = Double(UIcenter_start.x -  center.x )
            let dy = Double(UIcenter_start.y -  center.y )
            
            mas.X = X_start + dx * scale - (Double(PICcenter_start.x) - X_start) * (factor - 1)
            mas.Y = Y_start - dy * scale - (Double(PICcenter_start.y) - Y_start) * (factor - 1)
            updateFrame(finish:false,scale:scale)
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch presentState{
        case .Zooming,.Dragging:
            initialstate = false
            updateFrame(finish:true,scale: mas.Scale)
        default:
            break
        }
        presentState = .NoTouch
    }
    
    
    func updateFrame(finish:Bool,scale:Double){
        
        var scale = scale
        if finish {
            if scale < Scale_MIN {
                scale = Scale_MIN
            }
            if scale > Scale_MAX {
                scale = Scale_MAX
            }
            let p0 = UI2Pic(CGPoint.zero)
            let p1 = UI2Pic(CGPoint(x:mas.WX,y:mas.WY))
            if p0.x < -CGFloat(Scale_MAX)*mas.WX/2 {
                mas.X += Double(-CGFloat(Scale_MAX)*mas.WX/2-p0.x)
            }
            if p1.x > CGFloat(Scale_MAX)*mas.WX/2 {
                mas.X += Double(CGFloat(Scale_MAX)*mas.WX/2-p1.x)
            }
            if p0.y > CGFloat(Scale_MAX)*mas.WY/2 {
                mas.Y += Double(CGFloat(Scale_MAX)*mas.WY/2-p0.y)
            }
            if p1.y < -CGFloat(Scale_MAX)*mas.WY/2 {
                mas.Y += Double(-CGFloat(Scale_MAX)*mas.WY/2-p1.y)
            }
            print("new scale:\(scale), old scale:\(scaleBeforeMove)");
            let rmv = mas.pics.filter{$0.pic.Scale <= scale}
            for r in rmv{
                r.pic.stop = true
                r.pic.image = nil
                r.layer.removeFromSuperlayer()
            }
            mas.pics = mas.pics.filter{$0.pic.Scale > scale}
            for p in mas.pics{
                p.pic.stop = true
            }
            let l = CALayer()
            let mp = MasPic(update: { p in
                if let img = p.image{
                    DispatchQueue.main.async{
                        l.contents = img
                        self.setNeedsDisplay()
                    }
                }
            })
            mp.calc(WZ:mas.WZ)
            layer.addSublayer(l)
            mas.pics.append((pic:mp,layer:l))
        }else{
            CATransaction.begin()
            CATransaction.setDisableActions(true)
        }
        
        mas.Scale = scale
        if let mp = mas.mainPic{
            mainLayer.frame = UIRect(from: mp)
            for p in mas.pics{
                p.layer.frame = UIRect(from: p.pic)
            }
        }
        if !finish{
            CATransaction.commit()
        }
        mas.updater.flag.toggle()
    }
}

struct TouchView: UIViewRepresentable {
    typealias UIViewType = ZoomView
    @EnvironmentObject var redrawer:Updater

    func makeUIView(context: Context) -> ZoomView {
        print("makeUIView")
        return ZoomView()
    }
    func updateUIView(_ uiView: Self.UIViewType, context: Self.Context){
        print("updateuiview called")
        if redrawer.flag {
            print("redrawing")
            DispatchQueue.main.async {
                uiView.SizeChanged()
                mas.redrawer.flag = false
            }
        }
    }
}

struct TouchView_Previews: PreviewProvider {
    static var previews: some View {
        TouchView()
    }
}
