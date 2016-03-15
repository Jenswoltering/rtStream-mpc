//
//  Strategies.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 07.03.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import Foundation

class Strategies {

    //define strategies for transmission
    static var slowStart = {
        for possibleResolution in RTStream.possibleResolutions{
            if possibleResolution.key == RTStream.sharedInstance.myPeer?.minResolution {
                RTStream.sharedInstance.cameraManager.setPreset(possibleResolution.preset)
            }
        }
        RTStream.sharedInstance.cameraManager.setFramerate((RTStream.sharedInstance.myPeer?.minFramerate!)!)
        RTStream.sharedInstance.myPeer?.currentFramerate = RTStream.sharedInstance.myPeer?.minFramerate!
        Codec.H264_Decoder.setBitrate((RTStream.sharedInstance.myPeer?.minBitrate!)!)
    }
    
   static var increaseFramerate = {
        if (((RTStream.sharedInstance.myPeer?.currentFramerate!)! + 5) < 30) {
            RTStream.sharedInstance.cameraManager.setFramerate((RTStream.sharedInstance.myPeer?.currentFramerate!)! + 5)
            RTStream.sharedInstance.myPeer?.currentFramerate = (RTStream.sharedInstance.myPeer?.currentFramerate!)! + 5
        }else{
            RTStream.sharedInstance.cameraManager.setFramerate(30)
            RTStream.sharedInstance.myPeer?.currentFramerate = 30
            
        }
    }
    
    static var increaseBitrate = {
        if (((RTStream.sharedInstance.myPeer?.currentBitrate)! + 100) > 3000){
            RTStream.sharedInstance.myPeer?.currentBitrate = 3000
            Codec.H264_Decoder.setBitrate(3000)
        }else{
            RTStream.sharedInstance.myPeer?.currentBitrate = (RTStream.sharedInstance.myPeer?.currentBitrate)! + 100
            Codec.H264_Decoder.setBitrate((RTStream.sharedInstance.myPeer?.currentBitrate)!)
        }
    }
    
    static var decreaseBitrate = {
        if (((RTStream.sharedInstance.myPeer?.currentBitrate)! - 100) < RTStream.sharedInstance.myPeer?.minBitrate){
            RTStream.sharedInstance.myPeer?.currentBitrate = RTStream.sharedInstance.myPeer?.minBitrate
            Codec.H264_Decoder.setBitrate((RTStream.sharedInstance.myPeer?.minBitrate)!)
        }else{
            RTStream.sharedInstance.myPeer?.currentBitrate = (RTStream.sharedInstance.myPeer?.currentBitrate)! - 100
            Codec.H264_Decoder.setBitrate((RTStream.sharedInstance.myPeer?.currentBitrate)!)
        }
    }
    
   static var decreaseFramerate = {
        if (((RTStream.sharedInstance.myPeer?.currentFramerate!)! - 5) > 1) {
            RTStream.sharedInstance.cameraManager.setFramerate((RTStream.sharedInstance.myPeer?.currentFramerate!)! - 5)
            RTStream.sharedInstance.myPeer?.currentFramerate = (RTStream.sharedInstance.myPeer?.currentFramerate!)! - 5
        }else{
            RTStream.sharedInstance.cameraManager.setFramerate(1)
            RTStream.sharedInstance.myPeer?.currentFramerate = 1
        }
    }
    
    static var increaseResolution = {
        var valueCurrentResolution :Int = 0
        //find value of current resolution
        for possibleResolution in RTStream.possibleResolutions{
            if possibleResolution.key == RTStream.sharedInstance.myPeer?.currentResolution! {
                valueCurrentResolution = possibleResolution.value
            }
        }
        //find preset with next higher resolution
        if valueCurrentResolution < 5 {
            for possibleResolution in RTStream.possibleResolutions{
                if possibleResolution.value == valueCurrentResolution+1 {
                    RTStream.sharedInstance.cameraManager.setPreset(possibleResolution.preset)
                    RTStream.sharedInstance.myPeer?.currentResolution = possibleResolution.preset
                }
            }
        }
    }
    
    static var decreaseResolution = {
        var valueCurrentResolution :Int = 0
        //find value of current resolution
        for possibleResolution in RTStream.possibleResolutions{
            if possibleResolution.key == RTStream.sharedInstance.myPeer?.currentResolution! {
                valueCurrentResolution = possibleResolution.value
            }
        }
        //find preset with next higher resolution
        if valueCurrentResolution > 2 {
            for possibleResolution in RTStream.possibleResolutions{
                if possibleResolution.value == valueCurrentResolution - 1 {
                    RTStream.sharedInstance.cameraManager.setPreset(possibleResolution.preset)
                    RTStream.sharedInstance.myPeer?.currentResolution = possibleResolution.preset
                }
            }
        }
    }
    
    //End strategydefinition------------
}