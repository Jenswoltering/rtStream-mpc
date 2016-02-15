//
//  Codec.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 15.02.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import Foundation
import VideoToolbox

@objc protocol DecoderDelegate {
    optional func sampleOutput(video: CMSampleBuffer!)
}


class Decoder{
    var compressionSession : VTCompressionSessionRef?
    private var bitrate: Int!
    private var width:Int32 = 640
    private var height:Int32 = 480
    static let H264_Decoder=Decoder()
    var delegate:DecoderDelegate?
    
    static let defaultAttributes:[NSString: AnyObject] = [
        kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA),
        kCVPixelBufferIOSurfacePropertiesKey: [:],
        kCVPixelBufferOpenGLESCompatibilityKey: true,
    ]
    
    private var attributes:[NSString: AnyObject] {
        var attributes:[NSString: AnyObject] = Decoder.defaultAttributes
        attributes[kCVPixelBufferWidthKey] = NSNumber(int: width)
        attributes[kCVPixelBufferHeightKey] = NSNumber(int: height)
        return attributes
    }
    
    private var properties:[NSString: NSObject] {
        var properties:[NSString: NSObject] = [
            kVTCompressionPropertyKey_RealTime: kCFBooleanTrue,
            kVTCompressionPropertyKey_AverageBitRate: Int(bitrate),
            kVTCompressionPropertyKey_AllowFrameReordering: false
        ]
        return properties
    }
    
    private init(){
        var status:OSStatus
        status = VTCompressionSessionCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCMVideoCodecType_H264,
        nil,
        attributes,
        nil,
        callback,
        unsafeBitCast(self, UnsafeMutablePointer<Void>.self),
        &compressionSession)
        if (status == noErr) {
            status = VTSessionSetProperties(compressionSession!, properties)
        }
        if (status == noErr) {
            VTCompressionSessionPrepareToEncodeFrames(compressionSession!)
        }
    }
    

    private var callback:VTCompressionOutputCallback = {(
        outputCallbackRefCon:UnsafeMutablePointer<Void>,
        sourceFrameRefCon:UnsafeMutablePointer<Void>,
        status:OSStatus,
        infoFlags:VTEncodeInfoFlags,
        sampleBuffer:CMSampleBuffer?) in
        guard status == noErr else {
            print(status)
            return
        }
       
    }
    
}

class Encoder{
    
}