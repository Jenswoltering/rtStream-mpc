//
//  NALU.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 28.02.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import Foundation
import CoreMedia

class NALU {
    let rawBytes : NSMutableData?
    var spsData :NSMutableData = NSMutableData()
    var ppsData :NSMutableData = NSMutableData()
    var blockBuffer :NSMutableData = NSMutableData()
    
    init(streamRawBytes: NSData){
        self.rawBytes = NSMutableData(data: streamRawBytes)
        processStreamRawBytes()
    }
    
    func getBlockBuffer()->CMBlockBuffer{
        var newCMBlockBuffer :CMBlockBuffer?
        CMBlockBufferCreateWithMemoryBlock(
                                            nil,
                                            UnsafeMutablePointer<Void>(blockBuffer.bytes),
                                            (blockBuffer.length),
                                            kCFAllocatorNull,
                                            nil,
                                            0,
                                            (blockBuffer.length),
                                            0,
                                            &newCMBlockBuffer
        )
        return newCMBlockBuffer!
    }
    
    func getFormatDescription()->CMVideoFormatDescription{
        var status :OSStatus?
        var newCMVideoFormatDescription :CMVideoFormatDescription?
        let parameterSetPointers : [UnsafePointer<UInt8>]! = [UnsafePointer<UInt8>((spsData.bytes)),UnsafePointer<UInt8>((ppsData.bytes))]
        let parameterSetSizes : [Int] = [(spsData.length), (ppsData.length)]
        status = CMVideoFormatDescriptionCreateFromH264ParameterSets(
                                                                    kCFAllocatorDefault,
                                                                    2,
                                                                    parameterSetPointers,
                                                                    parameterSetSizes,
                                                                    4,
                                                                    &newCMVideoFormatDescription
        )
        if (status != noErr) {
            NSLog("An Error occured while creating Format description")
        }
        return newCMVideoFormatDescription!
    }
    
    func getSampleBuffer()->CMSampleBuffer{
        let samplebufferPtr = UnsafeMutablePointer<CMSampleBuffer?>.alloc(1)
        var err :OSStatus?
        let formatDescription: CMVideoFormatDescription = self.getFormatDescription()
        let blockBuffer :CMBlockBuffer = self.getBlockBuffer()
        let length = UnsafeMutablePointer<Int>.alloc(1)
        length.initialize(0)
        length.memory = self.blockBuffer.length
        let millis :Int64 = Int64(NSDate().timeIntervalSince1970*100000)
        let pts :CMTime = CMTimeMake(millis, 1000000000)
        var sampleTimingInfo = CMSampleTimingInfo(duration: kCMTimeInvalid, presentationTimeStamp: pts, decodeTimeStamp: kCMTimeInvalid)
        err = CMSampleBufferCreate(
                                    kCFAllocatorDefault,
                                    blockBuffer,
                                    true,
                                    nil,
                                    nil,
                                    formatDescription,
                                    1,
                                    1,
                                    &sampleTimingInfo,
                                    1,
                                    length,
                                    samplebufferPtr
        )
        if (err != noErr) {
            NSLog("An Error occured while creating sample buffer")
        }
        var sampleBuffer: CMSampleBuffer?
        sampleBuffer = samplebufferPtr.memory!
        return  sampleBuffer!
    }
    
    private func processStreamRawBytes(){
        if rawBytes != nil {

            var byteBuffer = [UInt8]()
            for i in 0..<rawBytes!.length {
                var commandInt:UInt = 0
                rawBytes!.getBytes(&commandInt, range: NSMakeRange(i, 1))
                byteBuffer.append(UInt8(commandInt))
            }
            
            var spsStartCodeIndex :Int = 0
            var ppsStartCodeIndex :Int = 0
            var blockBufferStartCodeIndex :Int = 0
            var spsLength :Int = 0;
            var ppsLength :Int = 0;
            var blockBufferLength :Int = 0;
            var foundStartcodes = 0

            for var n = 0; n < byteBuffer.count-3; ++n {
                if(byteBuffer[n] == 0x00 && byteBuffer[n+1] == 0x00 && byteBuffer[n+2] == 0x00 && byteBuffer[n+3] == 0x01){
                
                    foundStartcodes += 1
                    //Found sps unit
                    if foundStartcodes == 1{
                        spsStartCodeIndex = n
                    }
                    //found pps unit
                    if foundStartcodes == 2{
                        ppsStartCodeIndex = n
                    }
                    //found blockbuffer
                    if foundStartcodes == 3{
                        blockBufferStartCodeIndex = n
                        break
                    }
                }
            }
            
            spsLength = ppsStartCodeIndex - spsStartCodeIndex-4
            ppsLength = blockBufferStartCodeIndex - ppsStartCodeIndex-4
            blockBufferLength = (byteBuffer.count-4)-blockBufferStartCodeIndex-4
            
            for var x = spsStartCodeIndex+4; x < spsLength+4; ++x {
                spsData.appendBytes(&byteBuffer[x], length: 1)
            }
            //NSLog(spsData.description)
            for var x = ppsStartCodeIndex+4; x < ppsStartCodeIndex+4+ppsLength; ++x {
                ppsData.appendBytes(&byteBuffer[x], length: 1)
            }
            //NSLog(ppsData.description)
            for var x = blockBufferStartCodeIndex+4; x < blockBufferStartCodeIndex+4+blockBufferLength; ++x {
                blockBuffer.appendBytes(&byteBuffer[x], length: 1)
            }
        }
        
    }
    
    
}