//
//  CameraManager.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 08.02.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//
import UIKit
import Foundation
import AVFoundation
import CoreMedia
import CoreImage 

protocol CameraManagerDelegate {
    func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!)
    func cameraSessionDidOutputFrameAsH264(nalUnit: NSData!)
}

class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, CodecDelegate {
    
    var captureSession: AVCaptureSession!
    var captureDevice: AVCaptureDevice?
    var sessionQueue: dispatch_queue_t!
    var videoDeviceIn: AVCaptureDeviceInput!
    var videoDeviceOut: AVCaptureVideoDataOutput!
    var stillImageOutput: AVCaptureStillImageOutput!
    var useHardwareEncoding :Bool?
    var sessionDelegate: CameraManagerDelegate?
    var outputQueue :[NSData] = []
    var test :Int = 0
    
    let criticalQueueAccess: dispatch_queue_t = dispatch_queue_create("accessOutputQueue", DISPATCH_QUEUE_CONCURRENT)

    
    
    override init(){
        super.init()
        captureSession = AVCaptureSession()
        //setPreset(AVCaptureSessionPreset640x480)
        captureSession.sessionPreset = AVCaptureSessionPreset1280x720
        sessionQueue = dispatch_queue_create("CameraQueue", DISPATCH_QUEUE_SERIAL)
        self.useHardwareEncoding = true;
        Codec.H264_Decoder.delegate=self
        setupCamera()
    }
    
    
    func setPreset(preset :String)->Bool{
        
        if self.captureSession.canSetSessionPreset(preset){
            captureSession.sessionPreset = preset
            return true
        }else{
            return false
        }
    }
    
    func setFramerate(fps :Int){
        do{
            try self.videoDeviceIn.device.lockForConfiguration()
            self.videoDeviceIn.device.activeVideoMinFrameDuration = CMTimeMake(1,Int32(fps))
            self.videoDeviceIn.device.activeVideoMaxFrameDuration = CMTimeMake(1,Int32(fps))
            self.videoDeviceIn.device.unlockForConfiguration()
        }catch{
        }
    }

    private func authorizeCamera() -> Bool {
        switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) {
        case .NotDetermined:
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (success) -> Void in
                if success {
                    self.setupCamera()
                }
            })
            return false
        case .Restricted, .Denied:
            let alert = UIAlertController(title: "Camera access denied", message: "Please enable camera access in Settings", preferredStyle: .Alert)
            let openSettings = UIAlertAction(title: "Settings", style: .Default, handler: { (_) -> Void in
                let url = NSURL(string:UIApplicationOpenSettingsURLString)!
                UIApplication.sharedApplication().openURL(url)
            })
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alert.addAction(openSettings)
            alert.addAction(cancel)
            return false
        case .Authorized:
            return true
        }
    }
    
    func setUseHardwareEncoding(aUseHardwareEncoding :Bool){
        self.useHardwareEncoding = aUseHardwareEncoding
    }
    func finishedEncoding(nalUnit: NSData) {
        self.sessionDelegate?.cameraSessionDidOutputFrameAsH264(nalUnit)
    }
    
    
    
    private func setupCamera(){
        if !authorizeCamera() {
            return
        }
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                }
            }
        }
        do {
            videoDeviceIn = try AVCaptureDeviceInput(device: captureDevice)
        } catch {
            return //No camera
        }
        videoDeviceOut = AVCaptureVideoDataOutput()
        videoDeviceOut.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString):NSNumber(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        videoDeviceOut.alwaysDiscardsLateVideoFrames = true
        videoDeviceOut.setSampleBufferDelegate(self, queue: sessionQueue)
        if captureSession.canAddInput(videoDeviceIn) {
            captureSession.addInput(videoDeviceIn)
        }
        if captureSession.canAddOutput(videoDeviceOut) {
            captureSession.addOutput(videoDeviceOut)
        }
    }
    
    func teardownCamera() {
        dispatch_async(sessionQueue, {
            self.captureSession.stopRunning()
        })
    }
    
    func startCamera() {
        dispatch_async(sessionQueue, {
//            var weakSelf: CameraManager? = self
//            self.runtimeErrorHandlingObserver = NSNotificationCenter.defaultCenter().addObserverForName(AVCaptureSessionRuntimeErrorNotification, object: self.sessionQueue, queue: nil, usingBlock: {
//                (note: NSNotification!) -> Void in
//                
//                let strongSelf: CameraSessionController = weakSelf!
//                
//                dispatch_async(strongSelf.sessionQueue, {
//                    strongSelf.session.startRunning()
//                })
//            })
            self.captureSession.startRunning()
       })
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
//        NSLog("output")
//        test += 1
//        if test == 100 {
//            NSLog("100 frames reached")
//            RTStream.sharedInstance.changeStrategy(Strategies.slowStart)
//        }
//        if test == 110 {
//            NSLog("110 frames reached")
//            RTStream.sharedInstance.changeStrategy(Strategies.increaseResolution)
//            //setPreset(AVCaptureSessionPreset1920x1080)
//        }
//        if test == 115 {
//            NSLog("115 frames reached")
//            RTStream.sharedInstance.changeStrategy(Strategies.decreaseFramerate)
//            //setPreset(AVCaptureSessionPreset1920x1080)
//        }
//        if test == 120 {
//            NSLog("120 frames reached")
//            RTStream.sharedInstance.changeStrategy(Strategies.increaseResolution)
//            //setPreset(AVCaptureSessionPreset1920x1080)
//        }
//        if test == 140 {
//            NSLog("120 frames reached")
//            RTStream.sharedInstance.changeStrategy(Strategies.increaseResolution)
//            //setPreset(AVCaptureSessionPreset1920x1080)
//        }
//        if test == 150 {
//            NSLog("120 frames reached")
//            RTStream.sharedInstance.changeStrategy(Strategies.increaseResolution)
//            //setPreset(AVCaptureSessionPreset1920x1080)
//        }
//        if test == 170 {
//            NSLog("120 frames reached")
//            RTStream.sharedInstance.changeStrategy(Strategies.increaseResolution)
//            //setPreset(AVCaptureSessionPreset1920x1080)
//        }
//        if test == 180 {
//            NSLog("120 frames reached")
//            RTStream.sharedInstance.changeStrategy(Strategies.increaseResolution)
//            //setPreset(AVCaptureSessionPreset1920x1080)
//        }
//        if test == 200 {
//            NSLog("120 frames reached")
//            RTStream.sharedInstance.changeStrategy(Strategies.increaseBitrate)
//            //setPreset(AVCaptureSessionPreset1920x1080)
//        }
//        if test == 240 {
//            NSLog("120 frames reached")
//            RTStream.sharedInstance.changeStrategy(Strategies.increaseBitrate)
//            //setPreset(AVCaptureSessionPreset1920x1080)
//        }
//        
//        if test == 260 {
//            NSLog("120 frames reached")
//            RTStream.sharedInstance.changeStrategy(Strategies.increaseBitrate)
//            //setPreset(AVCaptureSessionPreset1920x1080)
//        }
//        if test == 280 {
//            NSLog("120 frames reached")
//            RTStream.sharedInstance.changeStrategy(Strategies.increaseBitrate)
//            //setPreset(AVCaptureSessionPreset1920x1080)
//        }
//        
//        if test == 300 {
//            NSLog("120 frames reached")
//            RTStream.sharedInstance.changeStrategy(Strategies.increaseBitrate)
//            //setPreset(AVCaptureSessionPreset1920x1080)
//        }
//        if test == 360 {
//            NSLog("120 frames reached")
//            RTStream.sharedInstance.changeStrategy(Strategies.slowStart)
//            //setPreset(AVCaptureSessionPreset1920x1080)
//        }
        if (connection.supportsVideoOrientation){
            //connection.videoOrientation = AVCaptureVideoOrientation.PortraitUpsideDown
            connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
        }
        if (self.useHardwareEncoding == true && Codec.H264_Decoder.readyForFrames == true){
            Codec.H264_Decoder.encodeFrame(sampleBuffer)
    
        }else{
            self.sessionDelegate?.cameraSessionDidOutputSampleBuffer(sampleBuffer)
        }
        
        
        
        
        //sessionDelegate?.cameraSessionDidOutputSampleBuffer?(sampleBuffer)
    }
    
}