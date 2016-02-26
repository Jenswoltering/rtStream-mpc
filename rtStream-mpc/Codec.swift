//
//  Codec.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 15.02.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import Foundation
import VideoToolbox
import AVFoundation

@objc protocol DecoderDelegate {
    optional func sampleOutput(video: CMSampleBuffer!)
}


class Decoder{
    
    var compressionSession : VTCompressionSessionRef?
    private var bitrate: Int = 160 * 1024
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
    
    func decodeFrame(uncompressedFrame:CMSampleBuffer){
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
        VTCompressionSessionCompleteFrames(compressionSession!,  CMSampleBufferGetPresentationTimeStamp(uncompressedFrame))
    
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
//            var myArray : NSMutableArray = NSMutableArray()
//            NSLog(sampleBuffer.debugDescription)
//            var copyOfSampleBuffer :CMSampleBufferRef = sampleBuffer!
//           
//            myArray.insertObject(sampleBuffer!, atIndex: 0)
////            var test :CMSampleBuffer!
////            test = buffer as! CMSampleBuffer
////            buffer = test
//            var data : NSData = NSKeyedArchiver.archivedDataWithRootObject(myArray)
            
            //Try to create a byte stream of the whole sample buffer
            
//            var unmanagedBufferCopy = UnsafeMutablePointer<CMSampleBuffer?>.alloc(1)
//            unmanagedBufferCopy.initialize(nil)
//            if (CMSampleBufferCreateCopy(kCFAllocatorDefault, sampleBuffer!, unmanagedBufferCopy) == noErr) {
//               sampleBuffer.
//               let bufferCopy = unmanagedBufferCopy.stride(through: UnsafeMutablePointer<CMSampleBuffer?>, by: Int)
//            }
            
            //try to create NALU packages
            
//            var stream=NSMutableData()
//            let startCodeLength :size_t = 4
//            let startCode:[UInt8] = [0x00, 0x00, 0x00, 0x01]
//            var formatDesrciption :CMFormatDescriptionRef = CMSampleBufferGetFormatDescription(sampleBuffer!)!
//            var numberOfParamterSets = UnsafeMutablePointer<Int>.alloc(1)
//            numberOfParamterSets.initialize(0)
//            //var numberOfParamterSets :Int = 1
//            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesrciption, 0, nil, nil, numberOfParamterSets, nil)
//            
//            for (var i=0; i < Int(numberOfParamterSets.memory); i++) {
//                var parameterSetPointer = UnsafeMutablePointer<UnsafePointer<UInt8>>.alloc(1)
//                parameterSetPointer.initialize(nil)
//                var parameterSetLength = UnsafeMutablePointer<Int>.alloc(1)
//                parameterSetLength.initialize(0)
//                CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesrciption,
//                    i,
//                    parameterSetPointer,
//                    parameterSetLength,
//                    nil,
//                    nil
//                )
//                
//                
//                stream.appendBytes(startCode, length: startCodeLength)
//                stream.appendBytes(parameterSetPointer, length: parameterSetLength.memory)
//            }
//            
//            
//            var blockBufferLength = UnsafeMutablePointer<Int>.alloc(1)
//            blockBufferLength.initialize(0)
//            var bufferDataPointer = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>.alloc(1)
//            bufferDataPointer.initialize(nil)
//            CMBlockBufferGetDataPointer(CMSampleBufferGetDataBuffer(sampleBuffer!)!,
//                0,
//                nil,
//                blockBufferLength,
//                bufferDataPointer
//            )
//            let AVCCHeaderLength:Int = 4
//            var bufferOffset :size_t = 0
//            while (bufferOffset < (blockBufferLength.memory - AVCCHeaderLength) ){
//                var NALUnitLength :UInt32 = 0
//                memcpy(&NALUnitLength, bufferDataPointer + bufferOffset, AVCCHeaderLength)
//                NALUnitLength = CFSwapInt32BigToHost(NALUnitLength)
//                stream.appendBytes(startCode, length: startCodeLength)
//                stream.appendBytes(bufferDataPointer + bufferOffset + AVCCHeaderLength, length: Int(NALUnitLength))
//                bufferOffset = bufferOffset + AVCCHeaderLength + Int(NALUnitLength)
//            }
//            
//            NSLog(stream.length.description)
       }
    }
    
}

class Encoder{
    
}