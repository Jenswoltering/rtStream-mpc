//
//  ViewController.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 16.01.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import UIKit
import AVFoundation
import MultipeerConnectivity

class DebugViewController: UIViewController {
    @IBOutlet weak var RTTButton: UIButton!
    var displayLayer = AVSampleBufferDisplayLayer()
    var rtStream :RTStream?
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        rtStream = RTStream.sharedInstance
        displayLayer.frame = self.view.bounds
        self.view.layer.addSublayer(displayLayer)
//        var controlTimebase :CMTimebaseRef?
//        CMTimebaseCreateWithMasterClock(kCFAllocatorDefault , CMClockGetHostTimeClock(), &controlTimebase)
//        displayLayer.controlTimebase = controlTimebase
//        CMTimebaseSetTime(displayLayer.controlTimebase!, CMTime(value: 5, timescale: 1))
//        CMTimebaseSetRate(displayLayer.controlTimebase!, 1)
        displayLayer.backgroundColor = UIColor.redColor().CGColor
    }

    func sampleOutput(frame: CMSampleBuffer!, pts:CMTime) {
        if frame != nil {
//            var newFrame: CMSampleBuffer?
//            var sampleTimingInfo = CMSampleTimingInfo(duration: kCMTimeInvalid, presentationTimeStamp: pts, decodeTimeStamp: kCMTimeInvalid)
//            CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, frame, 1, &sampleTimingInfo, &newFrame)
            
           // NSLog(newFrame.debugDescription)
            displayLayer.enqueueSampleBuffer(frame!)
            displayLayer.setNeedsDisplay()
        }
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

