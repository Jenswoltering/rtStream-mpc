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
    var rTTtimer :NSTimer!
    var statusTimer :NSTimer!
    var noBadNews :Int = 0
    init(parent:RTStream , transportManager: MCManager) {
        self.parent = parent
        self.transportManager = transportManager
    }
    
    func startControlTimers(){
        self.rTTtimer = NSTimer.scheduledTimerWithTimeInterval(3.00, target: self, selector: #selector(ControlChanelManager.determineRoundTripTime), userInfo: nil, repeats: true)
        self.statusTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(ControlChanelManager.statusCheck), userInfo: nil, repeats: true)
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
    
//    var message : [String:AnyObject] = [
//        //defined packagetypes
//        "type":"hello",
//        //current time in millisecons
//        "timestamp": 12345,
//        //some data convertible to NSData
//        "payload" : "someData"
//        
//        ]
    
    //will be only called when connected
    func connectedDevicesChanged(mcManager : MCManager, connectedDevice: MCPeerID, didChangeState: Int) {
        var message : [String:AnyObject] = [
            "type":"hello",
        ]
        message["isBroadcaster"] = parent.myPeer?.isBroadcaster
        message["minResolution"] = parent.myPeer?.minResolution
        message["minFramerate"] =  parent.myPeer?.minFramerate
        message["minBitrate"] = parent.myPeer?.minBitrate
        message["currentResolution"] = parent.myPeer?.currentResolution
        message["currentFramerate"] =  parent.myPeer?.currentFramerate
        message["currentBitrate"] = parent.myPeer?.currentBitrate
        mcManager.sendMessageToPeer(connectedDevice, messageToSend:  NSKeyedArchiver.archivedDataWithRootObject(message))
    }
    
    
    func handleHelloMessage(msgDict :[String : AnyObject], fromPeer :MCPeerID){
        var isBroadcaster:Bool
        if msgDict["isBroadcaster"] as! Bool == false{
            isBroadcaster=false}
        else{
            isBroadcaster=true
        }
        parent?.addPeer(fromPeer, isBroacaster: isBroadcaster, optionalInfos: msgDict)
    }
    
    func handleRTTRequest(aMsgDict :[String : AnyObject], fromPeer :MCPeerID){
        var msgDict = aMsgDict
        let incomingTimeInMillis = currentTimeMillis()
        //print("received rtt request")
        msgDict["type"] = "rttres"
        msgDict["processingTime"] = (currentTimeMillis() - incomingTimeInMillis) as AnyObject
        RTStream.sharedInstance.mcManager.sendMessageToPeer(fromPeer, messageToSend:  NSKeyedArchiver.archivedDataWithRootObject(msgDict))
    }
    
    func isFrameDelayed(peerToCompareWith :rtStreamPeer,frameToCheck :CMSampleBuffer)->Bool{
        //get the timing of the received frame
        let pts :CMTime = CMSampleBufferGetPresentationTimeStamp(frameToCheck)
        // Flag can be -1,0,1
        var frameDelay :Int32
        // pts < timeStampHistory -> frameDelay = -1
        // pts = timeStampHistory -> frameDelay = 0
        // pts > timeStampHistory -> frameDelay = 1
        frameDelay = CMTimeCompare(pts, (peerToCompareWith.timestampHistory))
        peerToCompareWith.timestampHistory = pts
        if frameDelay < 0 {
            //Frame is delayed
            //change strategie to slow start and dismiss frame
            NSLog("Frame is late")
            return true
        }else {
            let timeDiffernece = CMTimeSubtract(pts, (peerToCompareWith.timestampHistory))
            if timeDiffernece.timescale >= 1{
                return true
            }
        }
        return false
    }
    
    func handleRTTResponse( aMsgDict :[String : AnyObject], fromPeer :MCPeerID){
        var msgDict = aMsgDict
        let incomingTimeInMillis = currentTimeMillis()
        let processingTime = msgDict["processingTime"] as! Double
        msgDict["endTime"]=incomingTimeInMillis - processingTime
        self.getRoundTripTimeForPeer(fromPeer, response: true, rttPackage: msgDict)
    }
    
    func handleImage(msgDict :[String : AnyObject], fromPeer :MCPeerID){
        dispatch_async(RTStream.sharedInstance.GlobalUserInitiatedQueue, { () -> Void in
            let nalu :NALU = NALU(streamRawBytes: msgDict["frame"] as! NSData)
            let rtStreamPeer = RTStream.sharedInstance.getRtStreamPeerByPeerID(fromPeer)
            if rtStreamPeer != nil {
                let naluSampleBuffer :CMSampleBuffer = nalu.getSampleBuffer()
                
                if self.isFrameDelayed(rtStreamPeer!, frameToCheck: naluSampleBuffer){
                    self.noBadNews = 0
                    //Inform sender about delay
                }else{
                    let framenumber = msgDict["frameNumber"] as! Int
                    NSLog(framenumber.description)
                    RTStream.sharedInstance.offerFrame(naluSampleBuffer, fromPeer: fromPeer)
                }
                
                
//                //get the timing of the received frame
//                let pts :CMTime = CMSampleBufferGetPresentationTimeStamp(naluSampleBuffer)
//                
//                // Flag can be -1,0,1
//                var frameDelay :Int32
//                
//                // pts < timeStampHistory -> frameDelay = -1
//                // pts = timeStampHistory -> frameDelay = 0
//                // pts > timeStampHistory -> frameDelay = 1
//                frameDelay = CMTimeCompare(pts, (rtStreamPeer?.timestampHistory)!)
//                
//                if frameDelay < 0 {
//                    //Frame is delayed 
//                    //change strategie to slow start and dismiss frame
//                    self.noBadNews = 0
//                    RTStream.sharedInstance.changeStrategy(Strategies.slowStart)
//                    NSLog("Frame is late")
//                }else {
//                    RTStream.sharedInstance.offerFrame(naluSampleBuffer, fromPeer: fromPeer)
//                }
//                rtStreamPeer?.timestampHistory = pts
            }
        })
    }
    
    func handleUpdate(msgDict :[String : AnyObject], fromPeer :MCPeerID){
        let rtStreamPeer = RTStream.sharedInstance.getRtStreamPeerByPeerID(fromPeer)
        //pass a dictionary with all settings that updated
        rtStreamPeer?.updateSettings(msgDict)
    }

    func handleStartMessage(msgDict :[String : AnyObject], fromPeer :MCPeerID){
        let rtStreamPeer = RTStream.sharedInstance.getRtStreamPeerByPeerID(fromPeer)
        //pass a dictionary with all settings that updated
        rtStreamPeer?.isBroadcaster = true
    }
    
    func handleStopMessage(msgDict :[String : AnyObject], fromPeer :MCPeerID){
        let rtStreamPeer = RTStream.sharedInstance.getRtStreamPeerByPeerID(fromPeer)
        //pass a dictionary with all settings that updated
         rtStreamPeer?.isBroadcaster = false
    }
    
    
    
    
    func incomingMassage(manager: MCManager, fromPeer: MCPeerID, msg: NSData) {
        
        var msgDict :[String:AnyObject]!
        msgDict = NSKeyedUnarchiver.unarchiveObjectWithData(msg) as? [String : AnyObject]
        
        switch msgDict!["type"] as! String {
        case "hello":
            handleHelloMessage(msgDict, fromPeer: fromPeer)
        case "rttreq":
            handleRTTRequest(msgDict, fromPeer: fromPeer)
        case "start":
            handleStartMessage(msgDict, fromPeer: fromPeer)
        case "stop":
            handleStopMessage(msgDict, fromPeer: fromPeer)
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
    
    func sendStartMessage(){
        let timestamp = currentTimeMillis()
        let message : [String:AnyObject] = [
            "type":"start",
            "timestamp": timestamp as Double
            ]
        RTStream.sharedInstance.mcManager.sendMessageToAllPeers(messageToSend:  NSKeyedArchiver.archivedDataWithRootObject(message))
    }
    
    func sendStopMessage(){
        let timestamp = currentTimeMillis()
        let message : [String:AnyObject] = [
            "type":"stop",
            "timestamp": timestamp as Double
        ]
        RTStream.sharedInstance.mcManager.sendMessageToAllPeers(messageToSend:  NSKeyedArchiver.archivedDataWithRootObject(message))
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
        case 0..<2:
            break
            //not good
        case 2..<3:
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
            if peer!.rttResponse?.count == 15 {
                var tmpDuration :Double=0
                for storedRttPackage: [String:AnyObject] in peer!.rttResponse! {
                    tmpDuration = tmpDuration + ((storedRttPackage["endTime"] as! Double) - (storedRttPackage["initTime"] as! Double))
                }
                tmpDuration = tmpDuration / Double((peer!.rttResponse?.count)!)
                
                peer?.roundTripTimeHistory = tmpDuration
                
                let tendency = peer!.getRoundTripTimeTendency()
                let roundTripTimeHistory = peer!.roundTripTimeHistory
                print("rrTime: " + tmpDuration.description)
                print("History: " + roundTripTimeHistory.description)
                print("Tendenz: " + tendency.description)
                if ((roundTripTimeHistory < tmpDuration) && (tendency >= 2)){
                    self.noBadNews = 0
                    switch tendency{
                    case 2:
                        RTStream.sharedInstance.changeStrategy(Strategies.decreaseBitrate)
                    case 3:
                        RTStream.sharedInstance.changeStrategy(Strategies.decreaseBitrate)
                        RTStream.sharedInstance.changeStrategy(Strategies.decreaseFramerate)
                    case 4:
                        RTStream.sharedInstance.changeStrategy(Strategies.decreaseBitrate)
                        RTStream.sharedInstance.changeStrategy(Strategies.decreaseResolution)
                    case 5:
                        break
                    default:
                        break
                        
                    }
                    NSLog("things are becoming worse")
                    //things are gettig bad
                    //self.noBadNews = 0
                }
                if ((roundTripTimeHistory > tmpDuration) && (tendency < -2)){
                    NSLog("things are getting better")
                    
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