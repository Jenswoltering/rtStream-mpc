//
//  ControlChanelManager.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 27.01.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class ControlChanelManager :MCManagerDelegate {
       
    init() {
        
    }
    
    func connectedDevicesChanged(manager : MCManager, connectedDevice: MCPeerID, didChangeState: Int) {
        var recipientAsArray: [MCPeerID] = []
        recipientAsArray.append(connectedDevice)
            let message = "Hello"
            manager.sendMessageToPeer(recipientAsArray, messageToSend: message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
}
    
    func incomingMassage(manager: MCManager, fromPeer: MCPeerID, msg: NSData) {
         let str = NSString(data: msg, encoding: NSUTF8StringEncoding) as! String
        print(str)
        
        
        var recipientAsArray: [MCPeerID] = []
        recipientAsArray.append(fromPeer)
        let message = " "
        manager.sendMessageToPeer(recipientAsArray, messageToSend: message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
    }
    


}