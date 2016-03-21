//
//  ControlChanelManager.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 27.01.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import CoreMedia
import AVFoundation

class ControlChanelManager :MCManagerDelegate {
    var usePayload:Bool = true
    var parent :RTStream!
    var transportManager:MCManager!
    //var rttResponse:[[String:AnyObject]]?=[]      //moved to ststreampeer
    var rTTtimer :NSTimer!
    var statusTimer :NSTimer!
    var noBadNews :Int = 0
    init(parent:RTStream , transportManager: MCManager) {
        self.parent = parent
        self.transportManager = transportManager
        
    }
    
    func startControlTimers(){
       self.rTTtimer = NSTimer.scheduledTimerWithTimeInterval(3.00, target: self, selector: Selector("determineRoundTripTime"), userInfo: nil, repeats: true)
        self.statusTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("statusCheck"), userInfo: nil, repeats: true)
    }
    
    func stopControlTimers(){
        if self.rTTtimer != nil {
            self.rTTtimer.invalidate()
            self.statusTimer.invalidate()
        }
        
    }
    
    func lostPeer(manager: MCManager, lostDevice: MCPeerID) {
        parent?.deletePeer(lostDevice)
    }
    
    func connectedDevicesChanged(manager : MCManager, connectedDevice: MCPeerID, didChangeState: Int) {
        var message : [String:AnyObject] = [
            "type":"hello",
        ]
        message["isBroadcaster"] = parent.myPeer?.isBroadcaster
        manager.sendMessageToPeer(connectedDevice, messageToSend:  NSKeyedArchiver.archivedDataWithRootObject(message))
    }
    
    
    func handleHelloMessage(msgDict :[String : AnyObject], fromPeer :MCPeerID){
        print("hello")
        var isBroadcaster:Bool
        if msgDict["isBroadcaster"] as! Bool == false{
            isBroadcaster=false}
        else{
            isBroadcaster=true
        }
        parent?.addPeer(fromPeer, isBroacaster: isBroadcaster)
    }
    
    func handleRTTRequest(aMsgDict :[String : AnyObject], fromPeer :MCPeerID){
        var msgDict = aMsgDict
        let incomingTimeInMillis = currentTimeMillis()
        //print("received rtt request")
        msgDict["type"] = "rttres"
        msgDict["processingTime"] = (currentTimeMillis() - incomingTimeInMillis) as AnyObject
        RTStream.sharedInstance.mcManager.sendMessageToPeer(fromPeer, messageToSend:  NSKeyedArchiver.archivedDataWithRootObject(msgDict))
    }
    
    func handleRTTResponse( aMsgDict :[String : AnyObject], fromPeer :MCPeerID){
        var msgDict = aMsgDict
        let incomingTimeInMillis = currentTimeMillis()
        let processingTime = msgDict["processingTime"] as! Double
        msgDict["endTime"]=incomingTimeInMillis - processingTime
        self.getRoundTripTimeForPeer(fromPeer, response: true, rttPackage: msgDict)
    }
    
    func handleImage(msgDict :[String : AnyObject], fromPeer :MCPeerID){
        let nalu :NALU = NALU(streamRawBytes: msgDict["frame"] as! NSData)
        let rtStreamPeer = RTStream.sharedInstance.getRtStreamPeerByPeerID(fromPeer)
        if rtStreamPeer != nil {
            let naluSampleBuffer :CMSampleBuffer = nalu.getSampleBuffer()
            var pts :CMTime = CMSampleBufferGetPresentationTimeStamp(naluSampleBuffer)
            NSLog(pts.value.description)
            //ToDo compare Timestamp
            RTStream.sharedInstance.offerFrame(naluSampleBuffer, fromPeer: fromPeer)
            //Codec.H264_Decoder.decodeFrame(nalu.getSampleBuffer())
            //rtStreamPeer?.setFrameToDisplay(nalu.getSampleBuffer())
        }
    }
    
    func handleUpdate(msgDict :[String : AnyObject], fromPeer :MCPeerID){
        let rtStreamPeer = RTStream.sharedInstance.getRtStreamPeerByPeerID(fromPeer)
        //pass a dictionary with all settings that updated
        rtStreamPeer?.updateSettings(msgDict)
        
    }

    
    func incomingMassage(manager: MCManager, fromPeer: MCPeerID, msg: NSData) {
        
        var msgDict :[String:AnyObject]!
        msgDict = NSKeyedUnarchiver.unarchiveObjectWithData(msg) as? [String : AnyObject]
        
        switch msgDict!["type"] as! String {
        case "hello":
            handleHelloMessage(msgDict, fromPeer: fromPeer)
        case "rttreq":
            handleRTTRequest(msgDict, fromPeer: fromPeer)
        case "rttres":
            //print("received rtt response")
            handleRTTResponse(msgDict, fromPeer: fromPeer)
        case "image":
            NSLog("Bildgröße: " + msg.length.description)
            handleImage(msgDict, fromPeer: fromPeer)
        case "update":
            handleUpdate(msgDict, fromPeer: fromPeer)
        default:
            print("invalid message type")
        }

    }
    
    func currentTimeMillis() -> Double{
        let nowDouble = NSDate().timeIntervalSince1970
        return nowDouble*1000
    }
    
    dynamic func determineRoundTripTime(){
        RTStream.sharedInstance.mcManager.sendMessageToAllPeers(messageToSend: NSKeyedArchiver.archivedDataWithRootObject(createRoundTripTimePackage(currentTimeMillis())))
        
    }
    
    
    
    
    dynamic func statusCheck(){
        //check if system is running without negativ messages
        switch noBadNews {
        case 0:
            break
            //not good
        case 1..<3:
            RTStream.sharedInstance.changeStrategy(Strategies.increaseBitrate)
        case 3..<5:
            RTStream.sharedInstance.changeStrategy(Strategies.increaseBitrate)
            RTStream.sharedInstance.changeStrategy(Strategies.increaseFramerate)
        case 5..<10:
            RTStream.sharedInstance.changeStrategy(Strategies.increaseBitrate)
            RTStream.sharedInstance.changeStrategy(Strategies.increaseResolution)
        case 11..<20:
            RTStream.sharedInstance.changeStrategy(Strategies.increaseBitrate)
            RTStream.sharedInstance.changeStrategy(Strategies.increaseFramerate)
        default:
            noBadNews = 0
          NSLog("unknown status")
        }
        if RTStream.sharedInstance.connectedPeers.isEmpty == false {
            noBadNews = noBadNews + 1
        }
        
        
    }
    
    func createRoundTripTimePackage(currentTime :Double)->[String:AnyObject]{
        
        var message : [String:AnyObject] = [
            "type":"rttreq",
            "initTime":currentTime as AnyObject,
            "processingTime":0 as AnyObject,
            "endTime":0 as AnyObject
        ]
        
        if usePayload == true {
            message["payload"]="Lorem ipsum dolor sit amet,consetetur sadipscing elitr,sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et e"
        }
        return message
    }
    
    func getRoundTripTimeForPeer(peerID:MCPeerID,response:Bool, rttPackage:[String:AnyObject]?){
        if response == true {
            let peer = RTStream.sharedInstance.getRtStreamPeerByPeerID(peerID)
            peer!.rttResponse?.append(rttPackage!)
            if peer!.rttResponse?.count == 25 {
                var tmpDuration :Double=0
                for storedRttPackage: [String:AnyObject] in peer!.rttResponse! {
                    tmpDuration = tmpDuration + ((storedRttPackage["endTime"] as! Double) - (storedRttPackage["initTime"] as! Double))
                }
                tmpDuration = tmpDuration / Double((peer!.rttResponse?.count)!)
                
                peer?.roundTripTimeHistory = tmpDuration
                
                if ((peer!.roundTripTimeHistory < tmpDuration) && (peer!.getRoundTripTimeTendency() > 2)){
                    //things are gettig bad
                    //self.noBadNews = 0
                }
                if ((peer!.roundTripTimeHistory > tmpDuration) && (peer!.getRoundTripTimeTendency() < -2)){
                    //things are gettig better
                }

                //print(tmpDuration.description)
                peer!.rttResponse?.removeAll()
            }else{
                RTStream.sharedInstance.mcManager.sendMessageToPeer(peerID, messageToSend:  NSKeyedArchiver.archivedDataWithRootObject(createRoundTripTimePackage(currentTimeMillis())))
            }
            
        }else{
            RTStream.sharedInstance.mcManager.sendMessageToPeer(peerID, messageToSend:  NSKeyedArchiver.archivedDataWithRootObject(createRoundTripTimePackage(currentTimeMillis())))
        }
    }
    
    
    
    
    
    

}