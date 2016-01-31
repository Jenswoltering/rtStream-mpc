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

    let rtStrem = RTStream(serviceType: "Test")
    override func viewDidLoad() {
        
    
        super.viewDidLoad()
        
        //mcMananger.startBrowsing()
       
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

