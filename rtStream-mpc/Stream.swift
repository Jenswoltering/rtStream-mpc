//
//  Stream.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 02.03.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import Foundation
import CoreMedia

protocol StreamDelegate {
    func extractedFromStream(frame: CMSampleBuffer)
}

public class Stream :NSObject, NSStreamDelegate{
    var inputStream: NSInputStream?
    var outputStream: NSOutputStream?
    private var outBuffer: NSMutableData?
    private var inBuffer:Array<UInt8> = []
    var chunkSize :Int = 1024
    var readyToWrite :Bool = false
    var isWriting :Bool = false
    var streamDelegate:StreamDelegate?
    
    let criticalQueueOutput: dispatch_queue_t = dispatch_queue_create("critical1.Outqueue", DISPATCH_QUEUE_CONCURRENT)
    let criticalQueueInput: dispatch_queue_t = dispatch_queue_create("critical2.Inqueue", DISPATCH_QUEUE_CONCURRENT)

    public func getInputStream()-> NSInputStream{
        return self.inputStream!
    }
    public func getOutputStream()-> NSOutputStream{
        return self.outputStream!
    }
    public func getOutBuffer()-> NSMutableData?{
        if self.outBuffer != nil {
            return self.outBuffer!
        }else{
            return nil
        }
    }
    public func addDataToOutBuffer(dataToAppend :NSData){
        dispatch_barrier_sync(criticalQueueOutput, { () -> Void in
        self.readyToWrite = false
            if self.outBuffer != nil {
                if self.outBuffer?.length <= 100000 {
                self.outBuffer?.appendData(dataToAppend)
            }
            
            }else{
                self.outBuffer = NSMutableData()
                self.outBuffer?.appendData(dataToAppend)
            }
            NSLog(dataToAppend.length.description + "appended bytes")
            self.readyToWrite = true
        })
        //writeToStream()
        
    }
    
    
    public init(inputStream aInputStream:NSInputStream?, outputStream aOutputStream:NSOutputStream?){
        super.init()
        outBuffer = nil
        if aInputStream != nil{
            self.inputStream=aInputStream
            self.openStream(inputStream!)
        }
        if aOutputStream != nil{
            self.outputStream=aOutputStream
            NSLog((self.outputStream?.streamStatus.rawValue.description)!)
            openStream(self.outputStream!)
            NSLog((self.outputStream?.streamStatus.rawValue.description)!)
        }

    }
    
    deinit{
        if inputStream != nil{
            closeStream(inputStream!)
        }
        if outputStream != nil{
            closeStream(outputStream!)
        }
    }
    
    
    func pollingStream(dataToStream :NSData){
        self.addDataToOutBuffer(dataToStream)
       
        if self.isWriting == false {
            self.isWriting = true
            while (self.outputStream?.hasSpaceAvailable == true && self.outBuffer?.length > 10000 ){
                if self.outBuffer != nil{
                    writeToStream()
                }
            }
            self.isWriting = false
        }
    }
    
    
    func writeToStream(){
        dispatch_barrier_sync(criticalQueueOutput, { () -> Void in
            var pointerToOutBufferBytes = self.outBuffer?.bytes
            
            var lengthToRead :Int = self.chunkSize
            if (self.outBuffer?.length < self.chunkSize) {
                lengthToRead = (self.outBuffer?.length)!
            }
            var bufferForWriting = Array<UInt8>(count: lengthToRead, repeatedValue: 0)
            memcpy(UnsafeMutablePointer(bufferForWriting), pointerToOutBufferBytes!, lengthToRead)
            let lengthWritten = self.outputStream?.write(bufferForWriting, maxLength: lengthToRead)
            if lengthWritten != -1 {
                let rangeToDel :NSRange = NSMakeRange(0, lengthWritten!)
                self.outBuffer?.replaceBytesInRange(rangeToDel, withBytes: nil ,length: 0)
                NSLog("written")
            }
            pointerToOutBufferBytes = nil
            bufferForWriting.removeAll()
        })
    }
    
    public func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        //Get´s never called
        if (aStream == self.outputStream){
            switch eventCode{
            case NSStreamEvent.OpenCompleted:
                NSLog("opened")
            case NSStreamEvent.HasBytesAvailable:
                NSLog("HasBytesAvailable")
            case NSStreamEvent.HasSpaceAvailable:
                readyToWrite = true
                //writeToStream()
                //Testing stream-------------
                NSLog("HasSpaceAvailable")
                
                //---------------------------
                
            case NSStreamEvent.ErrorOccurred:
                NSLog("Errot")
                NSLog(NSStreamEvent.ErrorOccurred.rawValue.description)
            case NSStreamEvent.EndEncountered:
                NSLog("End")
            default:
                break
            }

        }
        if (aStream == inputStream){
            switch eventCode{
            case NSStreamEvent.OpenCompleted:
                NSLog("opened")
            case NSStreamEvent.HasBytesAvailable:
                NSLog("HasBytesAvailable")
                let buffer :Array<UInt8> = Array<UInt8>(count: self.chunkSize, repeatedValue: 0)
                let bytesRead = inputStream?.read(UnsafeMutablePointer(buffer), maxLength: self.chunkSize)
               
                    self.inBuffer.appendContentsOf(buffer)
                let foundEndcode :Int? = self.checkForEndcode(bytesRead!)
                if ( foundEndcode != nil) {
                    seperateFrameFromBuffer(foundEndcode!)
                }
                
            
            case NSStreamEvent.HasSpaceAvailable:
                NSLog("HasSpaceAvailable")
            case NSStreamEvent.ErrorOccurred:
                NSLog("Errot")
            case NSStreamEvent.EndEncountered:
                NSLog("End")
            default:
                break
            }
            
        }

    }
    
    private func seperateFrameFromBuffer(endcodePosition :Int){
        let naluData :NSMutableData = NSMutableData(bytes: UnsafePointer(self.inBuffer), length: endcodePosition)
        //NSLog(naluData.description)
        let rangeToDel :Range = Range(start: 0, end: endcodePosition+1)
        self.inBuffer.removeRange(rangeToDel)
        let nalu :NALU = NALU(streamRawBytes: naluData)
        NSLog(CMSampleBufferGetFormatDescription(nalu.getSampleBuffer()).debugDescription)
        //RTStream.sharedInstance.updateDisplay(nalu.getSampleBuffer())
    }
    
    private func checkForEndcode(sizeOfLastInput :Int)->Int?{
            //Its not the first imcoming data
            if inBuffer.count != sizeOfLastInput{
                for var n = self.inBuffer.count; n > inBuffer.count-self.chunkSize; n -= 1 {
                    if(inBuffer[n-3] == 0x01 && inBuffer[n-2] == 0xff && inBuffer[n-1] == 0x01 && inBuffer[n] == 0xff){
                        //Found an endcode at position n
                        return n
                    }
                }
                
            }else{
                for var n = self.inBuffer.count; n > inBuffer.count-self.chunkSize+3; n -= 1 {
                    if(inBuffer[n-3] == 0x01 && inBuffer[n-2] == 0xff && inBuffer[n-1] == 0x01 && inBuffer[n] == 0xff){
                        NSLog("found endcode2")
                        return n
                    }
                }
            }
        return nil
    }
    
    
    private func openStream(aStream :NSStream){
        
        if aStream == self.outputStream{
            self.outputStream!.delegate = self
            self.outputStream!.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            self.outputStream!.open()
        }
        if aStream == self.inputStream{
            self.inputStream!.delegate = self
            self.inputStream!.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            self.inputStream!.open()
        }
        
    }
    
    private func closeStream(aStream :NSStream){
        aStream.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        aStream.close()
        aStream.delegate = nil
    }
    
}