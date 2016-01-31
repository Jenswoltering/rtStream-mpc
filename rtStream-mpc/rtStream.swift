//
//  rtStream.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 26.01.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import Foundation

class RTStream{
    var mcManager:MCManager!
    var controlChanel:ControlChanelManager!
    init(serviceType:String){
        mcManager=MCManager(serviceTyeName: serviceType)
        controlChanel=ControlChanelManager()
        mcManager.delegate=controlChanel
        sleep(5)
        mcManager.startBrowsing()
    }
    
}
