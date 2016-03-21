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
                RTStream.sharedInstance.myPeer?.currentResolution = possibleResolution.key
            }
        }
        RTStream.sharedInstance.cameraManager.setFramerate((RTStream.sharedInstance.myPeer?.minFramerate!)!)
        RTStream.sharedInstance.myPeer?.currentFramerate = RTStream.sharedInstance.myPeer?.minFramerate!
    
    }
    
   static var increaseFramerate = {
        NSLog("current framerate " + (RTStream.sharedInstance.myPeer?.currentFramerate!.description)!)
        if (((RTStream.sharedInstance.myPeer?.currentFramerate!)! + 5) < 30) {
            RTStream.sharedInstance.myPeer?.currentFramerate = (RTStream.sharedInstance.myPeer?.currentFramerate!)! + 5
            if RTStream.sharedInstance.myPeer?.currentFramerate < RTStream.sharedInstance.myPeer?.minFramerate {
                RTStream.sharedInstance.myPeer?.currentFramerate = RTStream.sharedInstance.myPeer?.minFramerate
            }
            RTStream.sharedInstance.cameraManager.setFramerate((RTStream.sharedInstance.myPeer?.currentFramerate!)!)
            
        }else{
            RTStream.sharedInstance.cameraManager.setFramerate(30)
            RTStream.sharedInstance.myPeer?.currentFramerate = 30
            
        }
    }
    
    static var increaseBitrate = {
        if (((RTStream.sharedInstance.myPeer?.currentBitrate)! + 100) > 3000){
            RTStream.sharedInstance.myPeer?.currentBitrate = 3000
            //Codec.H264_Decoder.updateCompressionSession((RTStream.sharedInstance.myPeer?.currentResolution)!)
        }else{
            RTStream.sharedInstance.myPeer?.currentBitrate = (RTStream.sharedInstance.myPeer?.currentBitrate)! + 100
            if RTStream.sharedInstance.myPeer?.currentBitrate < RTStream.sharedInstance.myPeer?.minBitrate{
                RTStream.sharedInstance.myPeer?.currentBitrate = RTStream.sharedInstance.myPeer?.minBitrate
            }
            //Codec.H264_Decoder.updateCompressionSession((RTStream.sharedInstance.myPeer?.currentResolution)!)
        }
    }
    
    static var decreaseBitrate = {
        if (((RTStream.sharedInstance.myPeer?.currentBitrate)! - 100) < RTStream.sharedInstance.myPeer?.minBitrate){
            RTStream.sharedInstance.myPeer?.currentBitrate = RTStream.sharedInstance.myPeer?.minBitrate
            //Codec.H264_Decoder.updateCompressionSession((RTStream.sharedInstance.myPeer?.currentResolution)!)
        }else{
            RTStream.sharedInstance.myPeer?.currentBitrate = (RTStream.sharedInstance.myPeer?.currentBitrate)! - 100
            //Codec.H264_Decoder.updateCompressionSession((RTStream.sharedInstance.myPeer?.currentResolution)!)
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
        NSLog((RTStream.sharedInstance.myPeer?.currentResolution!)!)
        var valueCurrentResolution :Int = 0
        //find value of current resolution
        for possibleResolution in RTStream.possibleResolutions{
            if possibleResolution.key == RTStream.sharedInstance.myPeer?.currentResolution! {
                valueCurrentResolution = possibleResolution.value
                break
            }
        }
        //find preset with next higher resolution
        if valueCurrentResolution < 5 {
            for possibleResolution in RTStream.possibleResolutions{
                if possibleResolution.value == valueCurrentResolution+1 {
                    RTStream.sharedInstance.cameraManager.setPreset(possibleResolution.preset)
                    RTStream.sharedInstance.myPeer?.currentResolution = possibleResolution.key
                    //Codec.H264_Decoder.updateCompressionSession((RTStream.sharedInstance.myPeer?.currentResolution)!)
                    break
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
                    //Codec.H264_Decoder.updateCompressionSession((RTStream.sharedInstance.myPeer?.currentResolution)!)

                }
            }
        }
    }
    
    //End strategydefinition------------
}