//
//  ViewController.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 16.01.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController {
    @IBOutlet weak var RTTButton: UIButton!

    var rtStream :RTStream?
    override func viewDidLoad() {
        
        super.viewDidLoad()
        rtStream = RTStream.sharedInstance
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

