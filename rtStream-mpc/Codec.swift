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

@objc protocol CodecDelegate {
    optional func sampleOutput(video: CMSampleBuffer!)
}


class Codec {
    
    private var compressionRate:CGFloat = 0.4
    private var width:Int = 640
    private var height:Int = 480
    let myapi: EAGLRenderingAPI = EAGLRenderingAPI.OpenGLES2
    let context : CIContext!
    let eagleContext :EAGLContext!
    static let JPEG=Codec()
    var delegate:CodecDelegate?
    
    private init(){
        eagleContext = EAGLContext(API: myapi)
        context = CIContext(EAGLContext: eagleContext, options: nil)

    }
    
    func setCompressionRate(compressionRate:CGFloat){
        self.compressionRate = compressionRate
    }
    
    func decodeFrame(uncompressedFrame:CMSampleBuffer, completion: () -> Void ){
        //var formatDesrciption :CMFormatDescriptionRef = CMSampleBufferGetFormatDescription(uncompressedFrame)!
        let imageBuffer :CVImageBufferRef =  CMSampleBufferGetImageBuffer(uncompressedFrame)!
        CVPixelBufferLockBaseAddress(imageBuffer,0)
        let ciImage = CIImage(CVPixelBuffer: imageBuffer)
        let cgImg = self.context.createCGImage(ciImage, fromRect: ciImage.extent)
        let uiImage = UIImage(CGImage: cgImg)
        var compressedImage = UIImageJPEGRepresentation(uiImage, compressionRate)
        completion()
    }
}
