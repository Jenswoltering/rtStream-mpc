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
        //rtStream?.rtstreamDelegate = self
        displayLayer.frame = self.view.bounds
        self.view.layer.addSublayer(displayLayer)
        displayLayer.backgroundColor = UIColor.redColor().CGColor
    }
    
    func displayFrame(frame: CMSampleBuffer, fromPeer :MCPeerID) {
        self.displayLayer.enqueueSampleBuffer(frame)
        self.displayLayer.setNeedsDisplay()
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

