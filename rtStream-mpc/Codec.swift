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
    func preparedFrameForStream(stream: NSData)
}

class Codec {
    
    var compressionSession : VTCompressionSessionRef?
    private var bitrate: Int = 35000000
    private var width:Int32 = 1280
    private var height:Int32 = 720
    let startCodeLength :size_t!
    let startCode:[UInt8]!
    let stopCode:[UInt8]!
    var decompressionSession : VTDecompressionSession? = nil
    let decoderParameters = NSMutableDictionary()
    let destinationPixelBufferAttributes = NSMutableDictionary()
    var outputCallback = VTDecompressionOutputCallbackRecord()
    static let H264_Decoder=Codec()
    var delegate:CodecDelegate?
    
    static let defaultAttributes:[NSString: AnyObject] = [
        kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_422YpCbCr8),
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
        self.startCodeLength  = 4
        self.startCode = [0x00, 0x00, 0x00, 0x01]
        self.stopCode = [0x00, 0x00, 0x00, 0x11]
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
        self.destinationPixelBufferAttributes.setValue(NSNumber(unsignedInt: kCVPixelFormatType_32BGRA), forKey: kCVPixelBufferPixelFormatTypeKey as String)
        
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
            
        }else{
            if(initDecompressionSession(encodedFrame) == true){
                decodeFrame(encodedFrame)
            }
        }
    }
    
    func encodeFrame(uncompressedFrame:CMSampleBuffer){
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
    
    func processFrameForStream(sampleBuffer: CMSampleBuffer?){
        let sampleData=NSMutableData()
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
        err = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesrciption, 1, pps, ppsLength, ppsCount, nil )
        sampleData.appendBytes(Codec.H264_Decoder.startCode, length: Codec.H264_Decoder.startCodeLength)
        sampleData.appendBytes(sps.memory, length: spsLength.memory)
        sampleData.appendBytes(Codec.H264_Decoder.startCode, length: Codec.H264_Decoder.startCodeLength)
        sampleData.appendBytes(pps.memory, length: ppsLength.memory)
        
        
        if let blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer!) {
            let length = CMBlockBufferGetDataLength(blockBufferRef)
            let sampleBytes = UnsafeMutablePointer<Int8>.alloc(length)
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, sampleBytes)
            sampleData.appendBytes(Codec.H264_Decoder.startCode, length: Codec.H264_Decoder.startCodeLength)
            sampleData.appendBytes(sampleBytes, length: length)
            sampleData.appendBytes(Codec.H264_Decoder.stopCode, length: Codec.H264_Decoder.startCodeLength)
        }
        
        //Send the sampleBuffer here-------------------------------------
        
        
        
        //---------------------------------------------------------------
        
        let nalu:NALU = NALU(streamRawBytes: sampleData)
        let newSampleBuffer :CMSampleBuffer = nalu.getSampleBuffer()
        if CMFormatDescriptionEqual(CMSampleBufferGetFormatDescription(newSampleBuffer), formatDesrciption){
            NSLog("Equal")
        }
        let stream = NSData(data: sampleData)
        self.delegate?.preparedFrameForStream(stream)

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
                Codec.H264_Decoder.processFrameForStream(sampleBuffer)
        }
    }
}
