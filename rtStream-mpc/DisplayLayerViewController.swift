//
//  PlayerViewController.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 08.02.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import UIKit
import AVFoundation
import MultipeerConnectivity

class DisplayLayerViewController: UIViewController, RTStreamDelegate {
    var navtitle :String?
    
    @IBOutlet weak var displayViewWrapper: UIView!
    
    @IBOutlet weak var currentBitrateLabel: UILabel!
    @IBOutlet weak var currentFramerateLabel: UILabel!
    @IBOutlet weak var currentResolutionLabel: UILabel!
    var peerToDisplay :rtStreamPeer?
    let displayLayer = AVSampleBufferDisplayLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = self.navtitle
        displayViewWrapper.frame = self.view.bounds
        displayLayer.frame = self.view.bounds
        self.displayViewWrapper.layer.addSublayer(displayLayer)
        displayLayer.backgroundColor = UIColor.redColor().CGColor
        //self.view.layer.addSublayer(displayLayer)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        RTStream.sharedInstance.rtstreamDelegate = self
    }
    
    override func viewDidDisappear(animated: Bool) {
        RTStream.sharedInstance.rtstreamDelegate = nil
    }
    
    
    func displayFrame(frame: CMSampleBuffer, fromPeer: MCPeerID) {
        if fromPeer == peerToDisplay?.peerID {
           dispatch_async(dispatch_get_main_queue(), {
            self.displayLayer.enqueueSampleBuffer(frame)
            self.displayLayer.setNeedsDisplay()
            self.currentBitrateLabel.text = self.peerToDisplay?.currentBitrate?.description
            self.currentResolutionLabel.text = self.peerToDisplay?.currentResolution
            self.currentFramerateLabel.text = self.peerToDisplay?.currentFramerate?.description
           })
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
