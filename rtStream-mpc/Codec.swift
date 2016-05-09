//
//  Codec.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 15.02.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import UIKit
import Foundation
import CoreImage
import CoreGraphics
import CoreMedia
import VideoToolbox
import AVFoundation

protocol CodecDelegate {
    func finishedEncoding(nalUnit: NSData, timestamp: Int64)
}

class Codec {
    
    var compressionSession : VTCompressionSessionRef?
    private var bitrate: Int = (RTStream.sharedInstance.myPeer?.currentBitrate)! * 1024
    private let widthAndHeigthArray = RTStream.sharedInstance.myPeer?.currentResolution?.componentsSeparatedByString("x")
    private var width:Int32!
    private var height:Int32!
    private let startCodeLength :size_t!
    private let startCode:[UInt8]!
    private let stopCode:[UInt8]!
    private var invalidTimer :NSTimer!
    var readyForFrames :Bool = false
    var decompressionSession : VTDecompressionSession? = nil
    let decoderParameters = NSMutableDictionary()
    let destinationPixelBufferAttributes = NSMutableDictionary()
    var outputCallback = VTDecompressionOutputCallbackRecord()
    static let H264=Codec()
    var delegate:CodecDelegate?
    
    static let defaultAttributes:[NSString: AnyObject] = [
        kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange),
        kCVPixelBufferIOSurfacePropertiesKey: [:],
        kCVPixelBufferOpenGLESCompatibilityKey: true,
    ]
    
    private var attributes:[NSString: AnyObject] {
        var attributes:[NSString: AnyObject] = Codec.defaultAttributes
        attributes[kCVPixelBufferWidthKey] = NSNumber(int: width)
        attributes[kCVPixelBufferHeightKey] = NSNumber(int: height)
        return attributes
    }
    
    private var properties:[NSString: NSObject] {
        let properties:[NSString: NSObject] = [
            kVTCompressionPropertyKey_RealTime: kCFBooleanTrue,
            kVTCompressionPropertyKey_AverageBitRate: Int(bitrate),
            kVTCompressionPropertyKey_AllowFrameReordering: false
        ]
        return properties
    }
    
    private init(){
        self.width = Int32(widthAndHeigthArray![0])
        self.height = Int32(widthAndHeigthArray![1])
        self.startCodeLength  = 4
        self.startCode = [0x00, 0x00, 0x00, 0x01]
        self.stopCode = [0x01, 0xFF, 0x01, 0xFF]
        self.invalidTimer = NSTimer.scheduledTimerWithTimeInterval(1.00, target: self, selector: Selector("checkForInvalidCompressionSession"), userInfo: nil, repeats: true)
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
            self.readyForFrames = true
        }
        self.destinationPixelBufferAttributes.setValue(NSNumber(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange), forKey: kCVPixelBufferPixelFormatTypeKey as String)
        
    }
    
    func setResolution(resolution :String){
        let tempWidthAndHeigthArray = resolution.componentsSeparatedByString("x")
        self.width = Int32(tempWidthAndHeigthArray[0])
        self.height = Int32(tempWidthAndHeigthArray[1])
    }
    
    
    dynamic private func checkForInvalidCompressionSession(){
        let tmpWidthAndHeigthArray = RTStream.sharedInstance.myPeer?.currentResolution?.componentsSeparatedByString("x")
        let tmpWidth = Int32(tmpWidthAndHeigthArray![0])

        if ((RTStream.sharedInstance.myPeer?.currentBitrate)! * 1024 != self.bitrate)||(self.width!  != tmpWidth){
            NSLog("called timed update")
            self.updateCompressionSession((RTStream.sharedInstance.myPeer?.currentResolution)!)
        }
    }
    
    func updateCompressionSession(resolution :String){
        self.readyForFrames = false
        VTCompressionSessionInvalidate(compressionSession!)
        setResolution(resolution)
        self.bitrate = (RTStream.sharedInstance.myPeer?.currentBitrate)! * 1024
        var status:OSStatus
        status = VTCompressionSessionCreate(kCFAllocatorDefault,
            width,
            height,
            kCMVideoCodecType_H264,
            nil,
            attributes,
            nil,
            callback,
            unsafeBitCast(self, UnsafeMutablePointer<Void>.self),
            &compressionSession)
        NSLog("updated compression " + status.description)
        if (status == noErr){
            status = VTSessionSetProperties(compressionSession!, properties)
        }
        if (status == noErr) {
            VTCompressionSessionPrepareToEncodeFrames(compressionSession!)
            readyForFrames = true
        }

        
    }
    
    func initDecompressionSession(encodedFrame:CMSampleBuffer)->Bool{
        var status:OSStatus?
        var tmpDecompressionSession : VTDecompressionSession?
        let formatDescription :CMFormatDescription = CMSampleBufferGetFormatDescription(encodedFrame)!
        status = VTDecompressionSessionCreate(
                                            nil,
                                            formatDescription,
                                            decoderParameters,
                                            destinationPixelBufferAttributes,
                                            &outputCallback,
                                            &tmpDecompressionSession)
        if status != noErr {
            NSLog("Error while creating VTDecompressionSession")
            return false
        }
        self.decompressionSession=tmpDecompressionSession
        return true
    }
    
    func decodeFrame(encodedFrame:CMSampleBuffer){
        if decompressionSession != nil{
            var status:OSStatus?
            let flags:VTDecodeFrameFlags  = VTDecodeFrameFlags(rawValue: 0)
            var infoFlags = VTDecodeInfoFlags(rawValue: 0)
            
            status = VTDecompressionSessionDecodeFrame(
                                                        decompressionSession!,
                                                        encodedFrame,
                                                        flags,
                                                        nil,
                                                        &infoFlags)
            if (status != noErr) {
                NSLog("An Error occured while creating decompression session" + status.debugDescription)
            }
        }else{
            if(initDecompressionSession(encodedFrame) == true){
                decodeFrame(encodedFrame)
            }
        }
    }
    
    func encodeFrame(uncompressedFrame:CMSampleBuffer){
        if self.readyForFrames == true {
            var flags:VTEncodeInfoFlags = VTEncodeInfoFlags()
            let cvUncompressedFrame:CVImageBufferRef = CMSampleBufferGetImageBuffer(uncompressedFrame)!
            VTCompressionSessionEncodeFrame(
                compressionSession!,
                cvUncompressedFrame,
                CMSampleBufferGetPresentationTimeStamp(uncompressedFrame),
                CMSampleBufferGetDuration(uncompressedFrame),
                nil, nil,
                &flags
            )
            VTCompressionSessionCompleteFrames(compressionSession!, CMSampleBufferGetPresentationTimeStamp(uncompressedFrame))
        }
    }
    
    func processFrameForStream(sampleBuffer: CMSampleBuffer?){
        let sampleData =  NSMutableData()
        let formatDesrciption :CMFormatDescriptionRef = CMSampleBufferGetFormatDescription(sampleBuffer!)!
        let sps = UnsafeMutablePointer<UnsafePointer<UInt8>>.alloc(1)
        let pps = UnsafeMutablePointer<UnsafePointer<UInt8>>.alloc(1)
        let spsLength = UnsafeMutablePointer<Int>.alloc(1)
        let ppsLength = UnsafeMutablePointer<Int>.alloc(1)
        let spsCount = UnsafeMutablePointer<Int>.alloc(1)
        let ppsCount = UnsafeMutablePointer<Int>.alloc(1)
        sps.initialize(nil)
        pps.initialize(nil)
        spsLength.initialize(0)
        ppsLength.initialize(0)
        spsCount.initialize(0)
        ppsCount.initialize(0)
        var err : OSStatus
        err = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesrciption, 0, sps, spsLength, spsCount, nil )
        if (err != noErr) {
            NSLog("An Error occured while getting h264 parameter")
        }
        err = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesrciption, 1, pps, ppsLength, ppsCount, nil )
        if (err != noErr) {
            NSLog("An Error occured while getting h264 parameter")
        }
        sampleData.appendBytes(Codec.H264.startCode, length: Codec.H264.startCodeLength)
        sampleData.appendBytes(sps.memory, length: spsLength.memory)
        sampleData.appendBytes(Codec.H264.startCode, length: Codec.H264.startCodeLength)
        sampleData.appendBytes(pps.memory, length: ppsLength.memory)
        
        
        if let blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer!) {
            let length = CMBlockBufferGetDataLength(blockBufferRef)
            let sampleBytes = UnsafeMutablePointer<Int8>.alloc(length)
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, sampleBytes)
            sampleData.appendBytes(Codec.H264.startCode, length: Codec.H264.startCodeLength)
            sampleData.appendBytes(sampleBytes, length: length)
            sampleData.appendBytes(Codec.H264.stopCode, length: Codec.H264.startCodeLength)
            sampleBytes.dealloc(length)
        }

        let rts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer!).value as Int64
        let nalUnit = NSData(data: sampleData)
        self.delegate?.finishedEncoding(nalUnit, timestamp: rts)
        
        sps.destroy()
        spsLength.destroy()
        spsCount.destroy()
        pps.destroy()
        ppsLength.destroy()
        ppsCount.destroy()
        
        sps.dealloc(1)
        spsLength.dealloc(1)
        spsCount.dealloc(1)
        pps.dealloc(1)
        ppsLength.dealloc(1)
        ppsCount.dealloc(1)
 
        
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
        if (status == noErr){
            Codec.H264.processFrameForStream(sampleBuffer)
        }

    }
}
