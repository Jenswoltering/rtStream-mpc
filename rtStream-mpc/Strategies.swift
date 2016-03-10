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
        for possibleResolution in RTStream.sharedInstance.possibleResolutions{
            if possibleResolution.key == RTStream.sharedInstance.minResolution {
                RTStream.sharedInstance.cameraManager.setPreset(possibleResolution.preset)
            }
        }
        RTStream.sharedInstance.cameraManager.setFramerate(RTStream.sharedInstance.minFramerate!)
        RTStream.sharedInstance.currentFramerate = RTStream.sharedInstance.minFramerate!
        Codec.H264_Decoder.setBitrate(RTStream.sharedInstance.minBitrate!)
    }
    
   static var increaseFramerate = {
        if ((RTStream.sharedInstance.currentFramerate! + 5) < 30) {
            RTStream.sharedInstance.cameraManager.setFramerate(RTStream.sharedInstance.currentFramerate! + 5)
            RTStream.sharedInstance.currentFramerate = RTStream.sharedInstance.currentFramerate! + 5
        }else{
            RTStream.sharedInstance.cameraManager.setFramerate(30)
            RTStream.sharedInstance.currentFramerate = 30
            
        }
    }
    
   static var decreaseFramerate = {
        if ((RTStream.sharedInstance.currentFramerate! - 5) > 1) {
            RTStream.sharedInstance.cameraManager.setFramerate(RTStream.sharedInstance.currentFramerate! - 5)
            RTStream.sharedInstance.currentFramerate = RTStream.sharedInstance.currentFramerate! - 5
        }else{
            RTStream.sharedInstance.cameraManager.setFramerate(1)
            RTStream.sharedInstance.currentFramerate = 1
        }
    }
    
    static var increaseResolution = {
        var valueCurrentResolution :Int = 0
        //find value of current resolution
        for possibleResolution in RTStream.sharedInstance.possibleResolutions{
            if possibleResolution.key == RTStream.sharedInstance.currentResolution! {
                valueCurrentResolution = possibleResolution.value
            }
        }
        //find preset with next higher resolution
        if valueCurrentResolution < 5 {
            for possibleResolution in RTStream.sharedInstance.possibleResolutions{
                if possibleResolution.value == valueCurrentResolution+1 {
                    RTStream.sharedInstance.cameraManager.setPreset(possibleResolution.preset)
                }
            }
        }
    }
    
    static var decreaseResolution = {
        var valueCurrentResolution :Int = 0
        //find value of current resolution
        for possibleResolution in RTStream.sharedInstance.possibleResolutions{
            if possibleResolution.key == RTStream.sharedInstance.currentResolution! {
                valueCurrentResolution = possibleResolution.value
            }
        }
        //find preset with next higher resolution
        if valueCurrentResolution > 2 {
            for possibleResolution in RTStream.sharedInstance.possibleResolutions{
                if possibleResolution.value == valueCurrentResolution - 1 {
                    RTStream.sharedInstance.cameraManager.setPreset(possibleResolution.preset)
                }
            }
        }
    }
    
    //End strategydefinition------------
}