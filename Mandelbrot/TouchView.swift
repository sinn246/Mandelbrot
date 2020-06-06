//
//  TouchView.swift
//  Mandelbrot
//
//  Created by 西村信一 on 2020/06/04.
//  Copyright © 2020 sinn246. All rights reserved.
//

import SwiftUI
import UIKit

let MaxLoop:Int = 1024


class MasPic {
    func makeColor(z:Int) -> UIColor{
        let h = Double(z % 32) / 32.0
        return(UIColor(hue: CGFloat(h), saturation: 1.0, brightness: 1.0, alpha: 1.0))
    }
    var X0,Y0,X1,Y1:Double
    var Scale:Double
    var WX,WY:Int
    var image:UIImage? = nil
    init(x:Double,y:Double,scale:Double,wx:Int,wy:Int, completion:@escaping (MasPic)->()){
        X0 = x - Double(wx) / 2 * scale
        Y0 = y + Double(wy) / 2 * scale
        X1 = x + Double(wx) / 2 * scale
        Y1 = y - Double(wy) / 2 * scale
        let s = UIScreen.main.scale // Retina display scale is encapsulated in this class
        Scale = scale / Double(s)
        WX = Int(CGFloat(wx) * s)
        WY = Int(CGFloat(wx) * s)
        DispatchQueue.global(qos: .background).async {
            let ir = UIGraphicsImageRenderer(size: CGSize(width: self.WX, height: self.WY))
            self.image = ir.image{ctx in
                for y in 0..<self.WY {
                    for x in 0..<self.WX{
                        let c_r = self.X0 + Double(x) * self.Scale
                        let c_i = self.Y0 - Double(y) * self.Scale
                        var z_r = c_r
                        var z_i = c_i
                        for z in 1..<MaxLoop{
                            let zr2 = z_r*z_r
                            let zi2 = z_i*z_i
                            if zr2+zi2 > 4.0 {
                                self.makeColor(z: z).setFill()
                                ctx.fill(CGRect(x: x, y: y, width: 1, height: 1))
                                break
                            }
                            z_r = z_r*z_r - z_i*z_i + c_r
                            z_i = 2*z_r*z_i + c_i
                        }
                    }
                }
            }
            completion(self)
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
        Moving,
        TooManyTouches
    }
    /// const
    var ZOOM_MAX:CGFloat = 8.0
    var ZOOM_MIN:CGFloat = 1.0
    let BORDER_MAX:CGFloat = 80
    
    var picSize: CGSize = CGSize()
    var picCenter:CGPoint = CGPoint()
    var picCenterBeforeMove = CGPoint()
    var picZoom:CGFloat = 1.0 // screen 1-px = pic picZoom-px
    var picZoomBeforeMove:CGFloat = 1.0
    
    var picLayer: CALayer
    var gridLayer: CALayer
    var cornerLayers: [CALayer] = []
    var resultLayer:CALayer
    let markerSize:CGFloat = 6.0
    
    var theImage:UIImage? = nil
    var clippedImage:UIImage? = nil

    var presentState:CanvasTouchState = .NoTouch
    var timeInitial:TimeInterval = 0
    var circleImage:UIImage? = nil

    let corners = UnsafeMutablePointer<CGFloat>.allocate(capacity: 8)

    deinit {
        corners.deallocate()
    }
    
    required override init(frame F: CGRect) {
        picLayer = CALayer()
        gridLayer = CALayer()
        resultLayer = CALayer()
        let renderer = UIGraphicsImageRenderer(size: CGSize(width:16,height:16))
        super.init(frame: F)

        layer.insertSublayer(picLayer, at: 0)
        layer.insertSublayer(gridLayer, at: 1)
        layer.insertSublayer(resultLayer, at: 2)
        circleImage = renderer.image(actions: {rc in
            let ctx = rc.cgContext
            ctx.setFillColor(UIColor.green.cgColor)
            ctx.fillEllipse(in: CGRect(x:0, y:0, width:markerSize*2, height:markerSize*2))
        })
        for i in 0...3{
            let aCorner = CALayer()
            aCorner.contents = circleImage?.cgImage
            aCorner.frame = CGRect(x:-markerSize*2,y:-markerSize*2,
                                   width: markerSize*2,height: markerSize*2)
            cornerLayers.append(aCorner)
            layer.insertSublayer(aCorner, at: UInt32(3+i))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var ActiveRect:CGRect = CGRect()
    
    func setBGimage(image: UIImage){
        ActiveRect = frame
        if frame.size.height > frame.size.width{
            let w = (frame.size.height - frame.size.width) / 2
            ActiveRect.origin.y = w
            ActiveRect.size.height -= w*2
        }else{
            let w = (frame.size.width - frame.size.height) / 2
            ActiveRect.origin.x = w
            ActiveRect.size.width -= w*2
        }
        
        theImage = image
        picSize = image.size
        picLayer.contents = theImage?.cgImage
        
        picCenter.x = CGFloat(Double(picSize.width) / 2.0)
        picCenter.y = CGFloat(Double(picSize.height) / 2.0)
        picZoom  = max(picSize.width / frame.size.width, picSize.height / frame.size.height)
        ZOOM_MAX = min(picSize.width  / ActiveRect.width, picSize.height / ActiveRect.height)
        if picZoom > ZOOM_MAX {
            picZoom = ZOOM_MAX
        }
        ZOOM_MIN = 1.0
        if ZOOM_MAX < ZOOM_MIN {
            ZOOM_MIN = ZOOM_MAX / 2
        }
        let gridRenderer = UIGraphicsImageRenderer(size: frame.size)
        gridLayer.contents = gridRenderer.image(actions: {rc in
            let ctx = rc.cgContext
            ctx.setFillColor(UIColor.black.withAlphaComponent(0.2).cgColor)
            ctx.fill(frame)
            ctx.clear(ActiveRect)
        }).cgImage
        gridLayer.frame = frame
        resultLayer.frame = ActiveRect
        updateFrame(find: true)
    }

    
    func UI2Pic(point:CGPoint)->CGPoint{
        return CGPoint(
            x: picCenter.x - frame.size.width / CGFloat(2) * picZoom + point.x * picZoom,
            y: picCenter.y - frame.size.height / CGFloat(2) * picZoom + point.y * picZoom
        )
    }
    func Pic2UI(point:CGPoint)->CGPoint{
        return CGPoint(
            x: (point.x - picCenter.x) / picZoom + frame.size.width / CGFloat(2) ,
            y: (point.y - picCenter.y) / picZoom + frame.size.height / CGFloat(2)
        )
    }
    var D2_start:CGFloat = 0;
    var center_start:CGPoint = CGPoint()
    var cs_pic :CGPoint = CGPoint()

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        resultLayer.isHidden = true;
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
            let arr = Array(event!.allTouches!)
            let p1 = arr[0].previousLocation(in: self)
            if presentState != .Dragging{
                presentState = .Dragging
                picZoomBeforeMove = picZoom
                picCenterBeforeMove = picCenter
                center_start = p1
                cs_pic = UI2Pic(point: center_start)
            }
            moveByTouch(center:p1)
        }else if nTouch == 2{
            let arr = Array(event!.allTouches!)
            if presentState != .Moving{
                presentState = .Moving
                picZoomBeforeMove = picZoom
                picCenterBeforeMove = picCenter
                let p1 = arr[0].previousLocation(in: self)
                let p2 = arr[1].previousLocation(in: self)
                D2_start = (p1.x - p2.x)*(p1.x - p2.x) + (p1.y - p2.y)*(p1.y - p2.y)
                center_start = CGPoint(x:Double(p1.x + p2.x)/2, y: Double(p1.y + p2.y)/2)
                cs_pic = UI2Pic(point: center_start)
            }
            moveByTouches(arr: arr)
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch presentState{
        case .Moving,.Dragging:
            updateFrame(find:true)
        default:
            break
        }
        presentState = .NoTouch
    }
    
    
    func updateFrame(find:Bool){
        let p1 = Pic2UI(point: CGPoint.zero)
        let p2 = Pic2UI(point: CGPoint(x:picSize.width,y:picSize.height))
        let r = CGRect(origin: p1, size: CGSize(width: p2.x - p1.x, height: p2.y-p1.y))
        picLayer.frame = r
    }
    
    func moveByTouch(center:CGPoint){
        let dx = (center_start.x -  center.x )
        let dy = (center_start.y -  center.y )
        
        picCenter.x = picCenterBeforeMove.x + dx * picZoom //- (cs_pic.x - picCenterBeforeMove.x)
        picCenter.y = picCenterBeforeMove.y + dy * picZoom //- (cs_pic.y - picCenterBeforeMove.y)
        
        if ActiveRect.minX < (0 - picCenter.x) / picZoom + frame.size.width / CGFloat(2){
            picCenter.x = ( frame.size.width / CGFloat(2) - ActiveRect.minX ) * picZoom
        }
        if ActiveRect.minY <  (0 - picCenter.y) / picZoom + frame.size.height / CGFloat(2){
            picCenter.y = ( frame.size.height / CGFloat(2) - ActiveRect.minY ) * picZoom
        }
        if ActiveRect.maxX > (picSize.width - picCenter.x) / picZoom + frame.size.width / CGFloat(2){
            picCenter.x = ( frame.size.width / CGFloat(2) - ActiveRect.maxX ) * picZoom + picSize.width
        }
        if ActiveRect.maxY >  (picSize.height - picCenter.y) / picZoom + frame.size.height / CGFloat(2){
            picCenter.y = ( frame.size.height / CGFloat(2) - ActiveRect.maxY ) * picZoom + picSize.height
        }
        //        applyMagnetConstraints()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateFrame(find:false)
        CATransaction.commit()
    }


    func moveByTouches(arr:Array<UITouch>){
        let p0 = arr[0].location(in: self)
        let p1 = arr[1].location(in: self)
        let D2:CGFloat = (p1.x-p0.x)*(p1.x-p0.x) + (p1.y-p0.y)*(p1.y-p0.y)
        let center:CGPoint = CGPoint(x:(p1.x+p0.x)/CGFloat(2),y:(p1.y+p0.y)/CGFloat(2))
        
        var factor = D2_start / D2;
        
        picZoom = picZoomBeforeMove * factor
        if picZoom > ZOOM_MAX { picZoom = ZOOM_MAX }
        if picZoom < ZOOM_MIN { picZoom = ZOOM_MIN }
        factor = picZoom / picZoomBeforeMove
        
        let dx = (center_start.x -  center.x )
        let dy = (center_start.y -  center.y )
        
        picCenter.x = picCenterBeforeMove.x + dx * picZoom - (cs_pic.x - picCenterBeforeMove.x) * (factor - 1)
        picCenter.y = picCenterBeforeMove.y + dy * picZoom - (cs_pic.y - picCenterBeforeMove.y) * (factor - 1)
        
        if ActiveRect.minX < (0 - picCenter.x) / picZoom + frame.size.width / CGFloat(2){
            picCenter.x = ( frame.size.width / CGFloat(2) - ActiveRect.minX ) * picZoom
        }
        if ActiveRect.minY <  (0 - picCenter.y) / picZoom + frame.size.height / CGFloat(2){
            picCenter.y = ( frame.size.height / CGFloat(2) - ActiveRect.minY ) * picZoom
        }
        if ActiveRect.maxX > (picSize.width - picCenter.x) / picZoom + frame.size.width / CGFloat(2){
            picCenter.x = ( frame.size.width / CGFloat(2) - ActiveRect.maxX ) * picZoom + picSize.width
        }
        if ActiveRect.maxY >  (picSize.height - picCenter.y) / picZoom + frame.size.height / CGFloat(2){
            picCenter.y = ( frame.size.height / CGFloat(2) - ActiveRect.maxY ) * picZoom + picSize.height
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updateFrame(find:false)
        CATransaction.commit()
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

struct TouchView: UIViewRepresentable {
    typealias UIViewType = ZoomView
    @EnvironmentObject var m:Mandel

    static var body: some View {
        TouchView()
    }
    func makeUIView(context: Context) -> ZoomView {
        ZoomView(frame: .zero)
    }
    func updateUIView(_ uiView: Self.UIViewType, context: Self.Context){
        uiView.frame  = CGRect(x:0,y:0,width:m.WX,height:m.WY)
    }
    
}

struct TouchView_Previews: PreviewProvider {
    static var previews: some View {
        TouchView()
    }
}
