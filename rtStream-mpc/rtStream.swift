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

protocol RTStreamDelegate {
    //func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!)
    //func cameraSessionDidOutputFrameAsH264(nalUnit: NSData!)
    func displayFrame(frame :CMSampleBuffer, fromPeer :MCPeerID)
}


class RTStream :CameraManagerDelegate{
    
    var mcManager:MCManager!
    var controlChanel:ControlChanelManager!
    var myPeer:rtStreamPeer?
    var connectedPeers:[rtStreamPeer]=[]
    var cameraManager:CameraManager!
    var rtstreamDelegate :RTStreamDelegate?
    var streamBuffer:[NSMutableData]=[]
    var limitFramerateOutput :Int = 0
    var counterFramesSent :Int = 0
    var frameToDisplay :[CMSampleBuffer] = []
    private var outputQueue :[NSData] = []
    var debugDisplaylayer = AVSampleBufferDisplayLayer()
    var minResolution :String?
    var minFramerate :Int?
    var minBitrate :Int?
    var currentResolution :String?
    var currentFramerate :Int?
    var currentBitrate :Int?
   

    static let sharedInstance = RTStream(serviceType: "rtStream")
    
    struct resolution {
        var key :String
        var value :Int
        var preset :String
    }
    
    static var possibleResolutions :[resolution] = [
            resolution(key: "352x288",value: 1, preset: AVCaptureSessionPreset352x288),
            resolution(key: "640x480", value: 2 ,preset: AVCaptureSessionPreset640x480),
            resolution(key: "960x540",value: 3, preset: AVCaptureSessionPresetiFrame960x540),
            resolution(key: "1280x720", value: 4,preset: AVCaptureSessionPreset1280x720),
            resolution(key: "1920x1080", value: 5,preset: AVCaptureSessionPreset1920x1080)
    ]
    
    
    
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
    
    let criticalQueueAccess: dispatch_queue_t = dispatch_queue_create("accessOutputQueue.queue", DISPATCH_QUEUE_SERIAL)
    
    let sendingQueue: dispatch_queue_t = dispatch_queue_create("sendingQueue", DISPATCH_QUEUE_SERIAL)
    //------------------------------------------------------------
    
    
    private init(serviceType:String){
        
        mcManager=MCManager(serviceTyeName: serviceType)
        myPeer=rtStreamPeer(peerID: mcManager.getMyPeerID(),aIsBroadcaster: false)
        controlChanel=ControlChanelManager(parent: self, transportManager: mcManager)
        mcManager.delegate=controlChanel
        mcManager.startBrowsing()
    }
    
    
    func startBrowsing(){
        mcManager.startBrowsing()
    }

    func stopBrowsing(){
        mcManager.stopBrowsing()
    }
    
    
    func startBroadcasting(){
        cameraManager = CameraManager()
        cameraManager.sessionDelegate = self
        cameraManager.startCamera()
        controlChanel.startControlTimers()
    }
    
    func stopBroadcasting(){
        controlChanel.stopControlTimers()
        if cameraManager != nil {
            cameraManager.teardownCamera()
            cameraManager.sessionDelegate = nil
            cameraManager = nil
        }
       
        
    }
    
    func addPeer(connectedPeer:MCPeerID, isBroacaster:Bool){
        let newPeer=rtStreamPeer(peerID: connectedPeer, aIsBroadcaster: isBroacaster)
        self.connectedPeers.append(newPeer)
    }
    
    
    
    
    func changeStrategy(strategy: () -> Void){
        strategy()
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
    
    func offerFrame(frame :CMSampleBuffer , fromPeer: MCPeerID){
        let attachments :CFArrayRef = CMSampleBufferGetSampleAttachmentsArray(frame, true)!
        let dict :CFMutableDictionaryRef = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0),CFMutableDictionaryRef.self)
        //CFDictionaryAddValue(dict , unsafeAddressOf(kCMSampleAttachmentKey_DisplayImmediately), unsafeAddressOf(kCFBooleanTrue))
        CFDictionarySetValue(dict, unsafeAddressOf(kCMSampleAttachmentKey_DisplayImmediately), unsafeAddressOf(kCFBooleanTrue))
        self.rtstreamDelegate?.displayFrame(frame, fromPeer: fromPeer)
    }
    
    // Delegate methods
    func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!){
        
    }
    
    func sendFrame(){
        if self.connectedPeers.isEmpty == false {
            if self.outputQueue.isEmpty == false{
                //define message
                var message : [String:AnyObject] = ["type":"image"]
                dispatch_barrier_sync(criticalQueueAccess, { () -> Void in
                    let buffer = self.outputQueue.first
                    message["frame"] = buffer
                })
                RTStream.sharedInstance.mcManager.sendMessageToPeer((RTStream.sharedInstance.getConnectedPeers().last?.peerID)!, messageToSend: NSKeyedArchiver.archivedDataWithRootObject(message))
                dispatch_barrier_sync(criticalQueueAccess, { () -> Void in
                    self.outputQueue.removeFirst()
                })
            }
        }else{
            
        }
        

    }
    
    func getRtStreamPeerByPeerID(peerID :MCPeerID)->rtStreamPeer?{
       
        if let index = self.connectedPeers.indexOf({$0.peerID!.displayName == peerID.displayName}){
            return self.connectedPeers[index]
        }else{
            return nil
        }
        
    }
    
    func bufferOverflowAlert(){
        //inform all connected peers abount the buffer overflow
        //they should decrease their bitrate to lower the traffic
        let message : [String:AnyObject] = ["type":"bufferOverflow"]
        RTStream.sharedInstance.mcManager.sendMessageToAllPeers(messageToSend: NSKeyedArchiver.archivedDataWithRootObject(message))
        
        //decrease the framerate to prevent CPU/GPU-overload
        RTStream.sharedInstance.changeStrategy(Strategies.decreaseFramerate)
    }
    
    func cameraSessionDidOutputFrameAsH264(nalUnit: NSData!){
        NSLog("outputframeash264")
        dispatch_sync(GlobalUserInteractiveQueue, { () -> Void in
            if self.connectedPeers.isEmpty == false {
                if self.outputQueue.count < 3 {
                    self.outputQueue.append(nalUnit)
                    dispatch_sync(self.sendingQueue, {
                        self.sendFrame()
                    })
                    
                }else{
                    //Inform control chanel
                    NSLog("buffer overflow")
                }
            }
//            let nalu :NALU = NALU(streamRawBytes: nalUnit)
//            self.rtstreamDelegate?.displayFrame(nalu.getSampleBuffer(), fromPeer: (RTStream.sharedInstance.myPeer?.peerID)!)
 
        })
        
    }
}
