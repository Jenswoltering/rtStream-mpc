//
//  rtStream.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 26.01.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//
import UIKit
import AVFoundation
import CoreMedia
import CoreImage
import Foundation
import MultipeerConnectivity

class RTStream :CameraManagerDelegate{
    
    var mcManager:MCManager!
    var controlChanel:ControlChanelManager!
    var myPeer:rtStreamPeer?
    var connectedPeers:[rtStreamPeer]=[]
    var cameraManager:CameraManager!
    var streamBuffer:[NSMutableData]=[]
    
    static let sharedInstance = RTStream(serviceType: "rtStream")
    
    //Define global dispatch queues------------------------------------
    var GlobalMainQueue: dispatch_queue_t {
        return dispatch_get_main_queue()
    }
    
    var GlobalUserInteractiveQueue: dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
    }
    
    var GlobalUserInitiatedQueue: dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
    }
    
    var GlobalUtilityQueue: dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    }
    
    var GlobalBackgroundQueue: dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
    }
    //------------------------------------------------------------
    
    
    
    private init(serviceType:String){
        
        mcManager=MCManager(serviceTyeName: serviceType)
        myPeer=rtStreamPeer(peerID: mcManager.getMyPeerID(),isBroadcaster: true)
        connectedPeers.append(myPeer!)
        controlChanel=ControlChanelManager(parent: self, transportManager: mcManager)
        mcManager.delegate=controlChanel
        mcManager.startBrowsing()
        
        if myPeer?.name == "Jenss Iphone"{
            cameraManager = CameraManager()
            cameraManager.sessionDelegate = self
            cameraManager.startCamera()
        }
    }
    
    func addPeer(connectedPeer:MCPeerID, isBroacaster:Bool){
        
        let newPeer=rtStreamPeer(peerID: connectedPeer, isBroadcaster: isBroacaster)
        self.connectedPeers.append(newPeer)
    }
    
    func deletePeer(lostPeer:MCPeerID){
        
        if connectedPeers.isEmpty == false {
            for (index,peer) in connectedPeers.enumerate(){
                if peer.name == lostPeer.displayName{
                    connectedPeers.removeAtIndex(index)
                }
            }
        }
        
        self.connectedPeers = self.connectedPeers.filter({$0 !== lostPeer})
    }
    
    func getConnectedPeers()->[rtStreamPeer]{
        return self.connectedPeers
    }
    
    func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!) {
        
    }
    
    func cameraSessionDidOutputFrameAsH264Stream(stream: NSData!) {
        var msgDict :[String:AnyObject]! = [
            "type":"rttreq",
            "stream": ""
        ]

        msgDict!["type"] = "stream"
        msgDict!["stream"] = stream as AnyObject
        if connectedPeers.count == 2{
            mcManager.sendMessageToPeer(connectedPeers[1].peerID, messageToSend: NSKeyedArchiver.archivedDataWithRootObject(msgDict!))

        }
        NSLog("data coming")
    }
}
