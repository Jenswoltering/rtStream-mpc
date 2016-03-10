//
//  rtStreamPeer.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 02.02.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import CoreMedia

class rtStreamPeer {
    var peerID :MCPeerID
    var name :String
    var isBroadcaster :Bool?
   
    
    private var frameToDisplay :[CMSampleBuffer] = []
    
    init(peerID:MCPeerID, isBroadcaster:Bool){
        self.peerID = peerID
        self.name = peerID.displayName
        self.isBroadcaster = isBroadcaster
    }
    
    func getFrameToDisplay()->CMSampleBuffer?{
        if self.frameToDisplay.isEmpty == false {
            return self.frameToDisplay.last
        }else{
            return nil
        }
    }
    
    func setFrameToDisplay(frame :CMSampleBuffer){
        let attachments :CFArrayRef = CMSampleBufferGetSampleAttachmentsArray(frame, true)!
        let dict :CFMutableDictionaryRef = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0),CFMutableDictionaryRef.self)
        //CFDictionaryAddValue(dict , unsafeAddressOf(kCMSampleAttachmentKey_DisplayImmediately), unsafeAddressOf(kCFBooleanTrue))
        CFDictionarySetValue(dict, unsafeAddressOf(kCMSampleAttachmentKey_DisplayImmediately), unsafeAddressOf(kCFBooleanTrue))
        if self.frameToDisplay.isEmpty{
            self.frameToDisplay.append(frame)
        }else{
            self.frameToDisplay[0]=frame
        }
    }
    
    func updateSettings(setting :[String : AnyObject]){
        if let sIsBroadcaster = setting["isBroadcaster"] {
            self.isBroadcaster = sIsBroadcaster as? Bool
        }
//        if let sMinResolution = setting["minResolution"] {
//            self.minResolution = sMinResolution as? Int
//        }
//        if let sMinFrameRate = setting["minFrameRate"] {
//            self.minFrameRate = sMinFrameRate as? Int
//        }
//        if let sMinBitRate = setting["minBitRate"] {
//            self.minBitRate = sMinBitRate as? Int
//        }
//        if let sCurrentResolution = setting["currentResolution"] {
//            self.currentResolution = sCurrentResolution as? Int
//        }
//        if let sCurrentFramerate = setting["currentFramerate"] {
//            self.currentFramerate = sCurrentFramerate as? Int
//        }
//        if let sCurrentBitrate = setting["currentBitrate"] {
//            self.currentBitrate = sCurrentBitrate as? Int
//        }

        
    }
}