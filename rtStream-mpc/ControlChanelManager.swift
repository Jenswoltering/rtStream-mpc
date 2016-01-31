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
        let message : [String:AnyObject] = [
            "type":"hello",
            "role":"receiver"
        ]
        manager.sendMessageToPeer(connectedDevice, messageToSend:  NSKeyedArchiver.archivedDataWithRootObject(message))
}
    
    func incomingMassage(manager: MCManager, fromPeer: MCPeerID, msg: NSData) {
        let incomingTimeInMillis = currentTimeMillis()
        var msgDict :[String:AnyObject]?
        msgDict = NSKeyedUnarchiver.unarchiveObjectWithData(msg) as? [String : AnyObject]
        
        switch msgDict!["type"] as! String {
        case "hello":
            print("hello")
            manager.sendMessageToPeer(fromPeer, messageToSend:  NSKeyedArchiver.archivedDataWithRootObject(getRoundTripTime(currentTimeMillis())))
        case "rttreq":
            print("rtt")
            msgDict!["type"] = "rttres"
            msgDict!["processingTime"] = (currentTimeMillis() - incomingTimeInMillis) as AnyObject
            manager.sendMessageToPeer(fromPeer, messageToSend:  NSKeyedArchiver.archivedDataWithRootObject(msgDict!))
        case "rttres":
            print("rttresponse")
            let processingTime = msgDict!["processingTime"] as! Double
            msgDict!["endTime"]=incomingTimeInMillis - processingTime
            
            let duration = (msgDict!["endTime"] as! Double) - (msgDict!["initTime"] as! Double)
            
            print("processingTime \(msgDict!["processingTime"]?.description)")
            print("endTime \(duration.description)")
            
        default:
            print("invalid message type")
        }

    }
    
    func currentTimeMillis() -> Double{
        let nowDouble = NSDate().timeIntervalSince1970
        return nowDouble*1000
    }
    
    func getRoundTripTime(currentTime :Double)->[String:AnyObject]{
        let message : [String:AnyObject] = [
            "type":"rttreq",
            "initTime":currentTime as AnyObject,
            "processingTime":0 as AnyObject,
            "endTime":0 as AnyObject
        ]
        return message
    }

}