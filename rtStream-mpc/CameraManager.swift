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

@objc protocol CameraManagerDelegate {
    optional func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!)
}

class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession: AVCaptureSession!
    var captureDevice: AVCaptureDevice?
    var sessionQueue: dispatch_queue_t!
    var videoDeviceIn: AVCaptureDeviceInput!
    var videoDeviceOut: AVCaptureVideoDataOutput!
    var stillImageOutput: AVCaptureStillImageOutput!
    var sessionDelegate: CameraManagerDelegate?
    
    override init(){
        super.init()
        captureSession = AVCaptureSession()
        sessionQueue = dispatch_queue_create("CameraQueue", DISPATCH_QUEUE_SERIAL)
        setupCamera()
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
        videoDeviceOut.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString):NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
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
        if (connection.supportsVideoOrientation){
            //connection.videoOrientation = AVCaptureVideoOrientation.PortraitUpsideDown
            connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
        }
        if (connection.supportsVideoMirroring) {
            //connection.videoMirrored = true
            connection.videoMirrored = false
        }
        Decoder.H264_Decoder.decodeFrame(sampleBuffer)
        //sessionDelegate?.cameraSessionDidOutputSampleBuffer?(sampleBuffer)
    }
    
}