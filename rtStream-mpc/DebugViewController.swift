//
//  ViewController.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 16.01.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import UIKit
import CoreMedia
import AVFoundation
import MultipeerConnectivity

class DebugViewController: UIViewController, RTStreamDelegate {
    @IBOutlet weak var RTTButton: UIButton!
    var displayLayer = AVSampleBufferDisplayLayer()
    var rtStream :RTStream?
    var timer  = NSTimer()
    var testPTS :Int64=1
    override func viewDidLoad() {
        
        super.viewDidLoad()
        rtStream = RTStream.sharedInstance
        rtStream?.rtstreamDelegate = self
        displayLayer.frame = self.view.bounds
        self.view.layer.addSublayer(displayLayer)
//        var controlTimebase :CMTimebaseRef?
//        CMTimebaseCreateWithMasterClock(kCFAllocatorDefault , CMClockGetHostTimeClock(), &controlTimebase)
//        displayLayer.controlTimebase = controlTimebase
//       
//        CMTimebaseSetTime(displayLayer.controlTimebase!, CMTime(value: self.testPTS, timescale: 1))
//        CMTimebaseSetRate(displayLayer.controlTimebase!, 1)
        displayLayer.backgroundColor = UIColor.redColor().CGColor
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateImagesWithNotification", name: "NALU_ready", object: nil)
        //timer = NSTimer.scheduledTimerWithTimeInterval(0.04, target: self, selector: Selector("updateImages"), userInfo: nil, repeats: true)
    }
    
    func displayFrame(frame: CMSampleBuffer) {
        self.displayLayer.enqueueSampleBuffer(frame)
        self.displayLayer.setNeedsDisplay()
    }
    
    func updateImagesWithNotification(notification:NSNotification){
        //dispatch_async(dispatch_get_main_queue(),{
            let frame :CMSampleBuffer = notification.userInfo as! CMSampleBuffer
            self.displayLayer.enqueueSampleBuffer(frame)
            self.displayLayer.setNeedsDisplay()
        //})
    }
    
    func updateImages(){
        if RTStream.sharedInstance.connectedPeers.isEmpty == false {
            dispatch_async(dispatch_get_main_queue(),{

                let frame = RTStream.sharedInstance.connectedPeers[0].getFrameToDisplay()
                if frame != nil {
                    var newFrame: CMSampleBuffer?
                    if CMSampleBufferIsValid(frame!){
//                        self.testPTS += 1
//                        var sampleTimingInfo = CMSampleTimingInfo(duration: kCMTimeInvalid, presentationTimeStamp: CMTimeMake(self.testPTS, 1), decodeTimeStamp: kCMTimeInvalid)
//                        CMSampleBufferSetOutputPresentationTimeStamp(frame!, CMTimeMake(self.testPTS, 1))
//                        CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, frame!, 1, &sampleTimingInfo, &newFrame)
                        self.displayLayer.enqueueSampleBuffer(frame!)
                        self.displayLayer.setNeedsDisplay()
                        self.displayLayer.flush()
                        NSLog("valid")
                    }else{
                        NSLog("not valid")
                    }
                
                   
                }
            })
        }
    }
    
    func extractedFromStream(frame: CMSampleBuffer) {
        
            //            var newFrame: CMSampleBuffer?
            //            var sampleTimingInfo = CMSampleTimingInfo(duration: kCMTimeInvalid, presentationTimeStamp: pts, decodeTimeStamp: kCMTimeInvalid)
            //            CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, frame, 1, &sampleTimingInfo, &newFrame)
            
            // NSLog(newFrame.debugDescription)
            displayLayer.enqueueSampleBuffer(frame)
            displayLayer.setNeedsDisplay()
        

    }
    
    
    
    @IBAction func RTTPressed(sender: AnyObject) {
        if rtStream?.connectedPeers.isEmpty == false{
            rtStream?.controlChanel.getRoundTripTimeForPeer((rtStream?.connectedPeers.first?.peerID)!, response: false, rttPackage: nil)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

