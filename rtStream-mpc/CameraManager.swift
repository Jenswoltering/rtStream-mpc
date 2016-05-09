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
    func cameraSessionDidOutputFrameAsH264(nalUnit: NSData!, timestamp :Int64)
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
        captureSession.sessionPreset = AVCaptureSessionPreset1280x720
        sessionQueue = dispatch_queue_create("CameraQueue", DISPATCH_QUEUE_SERIAL)
        self.useHardwareEncoding = true;
        Codec.H264.delegate=self
        setupCamera()
    }
    
    func setPreset(preset :String)->Bool{
        var didSetPreset :Bool = false
        dispatch_async(sessionQueue, {
        if self.captureSession.canSetSessionPreset(preset){
            self.captureSession.sessionPreset = preset
            didSetPreset = true
        }else{
            didSetPreset = false
        }
        })
        if didSetPreset == true {
            return true
        }else{
            return false
        }
    }
    
    func setFramerate(fps :Int){
        dispatch_async(sessionQueue, {
        do{
            try self.videoDeviceIn.device.lockForConfiguration()
            self.videoDeviceIn.device.activeVideoMinFrameDuration = CMTimeMake(1,Int32(fps))
            self.videoDeviceIn.device.activeVideoMaxFrameDuration = CMTimeMake(1,Int32(fps))
            self.videoDeviceIn.device.unlockForConfiguration()
        }catch{
        }
        })
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
    
    func finishedEncoding(nalUnit: NSData, timestamp: Int64) {
        self.sessionDelegate?.cameraSessionDidOutputFrameAsH264(nalUnit, timestamp: timestamp)
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
            self.captureSession.startRunning()
       })
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        NSLog("camera raw outpu")
        if (connection.supportsVideoOrientation){
            connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
        }
        if (self.useHardwareEncoding == true && Codec.H264.readyForFrames == true){
            Codec.H264.encodeFrame(sampleBuffer)
    
        }else{
            self.sessionDelegate?.cameraSessionDidOutputSampleBuffer(sampleBuffer)
        }
        
    }
    
}