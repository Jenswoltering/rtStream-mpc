//
//  ViewController.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 16.01.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController , MCManagerDelegate {

    @IBOutlet weak var findpeer: UIButton!
    @IBOutlet weak var connectionLabel: UILabel!
    let mcMananger = MCManager()
    override func viewDidLoad() {
        
    
        super.viewDidLoad()
        mcMananger.delegate = self
        //mcMananger.startBrowsing()
       
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func connectedDevicesChanged(manager : MCManager, connectedDevices: [String]){
        NSOperationQueue.mainQueue().addOperationWithBlock {
            print("Connections: \(connectedDevices)")
        }
        
    }
    func colorChanged(manager : MCManager, colorString: String){
        
    }



}

