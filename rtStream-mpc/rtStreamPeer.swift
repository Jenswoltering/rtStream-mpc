//
//  rtStreamPeer.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 02.02.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import AVFoundation
import CoreMedia

class rtStreamPeer {
    private var initialzed:Bool = false
    var rttResponse:[[String:AnyObject]]?=[]
    private var _roundTripTimeHistory :[Double] = [0] {
        willSet(aNewValue){
            
        }
        didSet{
            if self.initialzed == true{
                if _roundTripTimeHistory.count == 5 {
                    _roundTripTimeHistory.removeAtIndex(0)
                }
//                if ((roundTripTimeHistory < _roundTripTimeHistory.last) && (getRoundTripTimeTendency() > 2)){
//                    //things are gettig bad
//                    notifyAboutNegativeTrend()
//                }
//                if ((roundTripTimeHistory > _roundTripTimeHistory.last) && (getRoundTripTimeTendency() < -2)){
//                    //things are gettig better
//                    notifyAboutPositiveTrend()
//                }
            }
            
        }

    }
    
    private var _peerID :MCPeerID? {
        willSet{
            
        }
        didSet{
            if self.initialzed == true{
               sendUpdate()
            }
            
        }
    }
    private var _name :String? {
        willSet{
            
        }
        didSet{
            if self.initialzed == true{
                sendUpdate()
            }
        }
    }
    private var _isBroadcaster :Bool? {
        willSet{
            
        }
        didSet{
            if self.initialzed == true{
                //RTStream.sharedInstance.s
                sendUpdate()
            }
        }
    }
    
    
    private var _minResolution :String? {
        willSet{
            
        }
        didSet{
            if self.initialzed == true{
                sendUpdate()
            }
        }
    }

     private var _minFramerate :Int? {
        willSet{
            
        }
        didSet{
            if self.initialzed == true{
                sendUpdate()
            }
        }
    }

    private var _minBitrate :Int? {
        willSet{
            
        }
        didSet{
            if self.initialzed == true{
                sendUpdate()
            }
        }
    }

    private var _currentResolution :String? {
        willSet{
            
        }
        didSet{
            if self.initialzed == true{
                sendUpdate()
            }
        }
    }

    private var _currentFramerate :Int? {
        willSet{
            
        }
        didSet{
            if self.initialzed == true{
                sendUpdate()
            }
        }
    }

    private var _currentBitrate :Int? {
        willSet{
            
        }
        didSet{
            if self.initialzed == true{
                sendUpdate()
            }
        }
    }


    var minResolution :String? {
        get {
            return _minResolution!
        }
        set(aNewvalue){
            if (aNewvalue  != _minResolution){
                _minResolution = aNewvalue
            }
        }
    }

    var minFramerate :Int? {
        get {
            return _minFramerate!
        }
        set(aNewvalue){
            if (aNewvalue  != _minFramerate){
                _minFramerate = aNewvalue
            }
        }
    }

    var minBitrate :Int? {
        get {
            return _minBitrate!
        }
        set(aNewvalue){
            if (aNewvalue  != _minBitrate){
                _minBitrate = aNewvalue
            }
        }
    }

    var currentResolution :String? {
        get {
            return _currentResolution!
        }
        set(aNewvalue){
            if (aNewvalue  != _currentResolution){
                _currentResolution = aNewvalue
            }
        }
    }

    var currentFramerate :Int? {
        get {
            return _currentFramerate!
        }
        set(aNewvalue){
            if (aNewvalue  != _currentFramerate){
                _currentFramerate = aNewvalue
            }
        }
    }

    var currentBitrate :Int? {
        get {
            return _currentBitrate!
        }
        set(aNewvalue){
            if (aNewvalue  != _currentBitrate){
                _currentBitrate = aNewvalue
            }
        }
    }

    var peerID :MCPeerID? {
        get {
            return _peerID!
        }
        set(aNewvalue){
            if (aNewvalue  != _peerID){
                _peerID = aNewvalue
            }
        }
    }
    
    var name :String? {
        get {
            return _name!
        }
        set(aNewvalue){
            if (aNewvalue  != _name){
               _name = aNewvalue
            }
        }
    }

    var isBroadcaster :Bool?{
        get {
            return _isBroadcaster!
        }
        set(aNewvalue){
            if (aNewvalue  != _isBroadcaster){
                _isBroadcaster = aNewvalue
            }
        }
    }
    
    var roundTripTimeHistory :Double{
        get {
            return _roundTripTimeHistory.reduce(0) { $0 + $1 } / Double(_roundTripTimeHistory.count)
        }
        set(aNewvalue){
            _roundTripTimeHistory.append(aNewvalue)
        }
    }

    private let defaultProperties :[String:AnyObject] = [
        "minResolution" : "640x480" as String,
        "minFramerate" : 15 as Int,
        "minBitrate" : 500 as Int
    ]

    
    init(peerID:MCPeerID, aIsBroadcaster:Bool ){
        self.peerID = peerID
        self.name = peerID.displayName
        self.isBroadcaster = aIsBroadcaster
        self.minResolution = self.defaultProperties["minResolution"] as? String
        self.minFramerate = self.defaultProperties["minFramerate"] as? Int
        self.minBitrate = self.defaultProperties["minBitrate"] as? Int
        self.currentResolution = self.minResolution
        self.currentFramerate = self.minFramerate
        self.currentBitrate = self.minBitrate
        self.initialzed = true
    }
    
    
    private func notifyAboutPositiveTrend(){
        
        NSLog("Things are getting better")
        
    }
    
    private func notifyAboutNegativeTrend(){
        NSLog("Things are getting worse")

        
    }
    
    private func sendUpdate(){
        //send update only when function is called by mypeer
        if (self.peerID == RTStream.sharedInstance.myPeer?.peerID)&&(RTStream.sharedInstance.connectedPeers.isEmpty == false){
            let updateMessage : [String:AnyObject] = [
                "type":"update",
                "isBroadcaster": self.isBroadcaster as! AnyObject,
                "minBitrate": self.minBitrate as! AnyObject,
                "minFramerate":  self.minFramerate as! AnyObject,
                "minResolution": self.minResolution as! AnyObject,
                "currentBitrate": self.currentBitrate as! AnyObject,
                "currentFramerate":  self.currentFramerate as! AnyObject,
                "currentResolution":  self.currentResolution as! AnyObject
            ]
            RTStream.sharedInstance.mcManager.sendMessageToAllPeers(messageToSend: NSKeyedArchiver.archivedDataWithRootObject(updateMessage))
            NSLog("send Update Message")
        }
    }
    
    func getRoundTripTimeTendency()->Int{
        var tendency :Int = 0
        if _roundTripTimeHistory.count > 1{
            for var i = 1; i < _roundTripTimeHistory.count; ++i {
                
                if (_roundTripTimeHistory[i-1] < _roundTripTimeHistory[i]){
                    tendency = tendency + 1
                }
                if(_roundTripTimeHistory[i-1] > _roundTripTimeHistory[i]){
                    tendency = tendency - 1
                }
                //print(tendency.description)
                
            }
        }
        return tendency
    }
    
    func updateSettings(setting :[String : AnyObject]){
        if let sIsBroadcaster = setting["isBroadcaster"] {
            self.isBroadcaster = sIsBroadcaster as? Bool
        }
        if let sMinResolution = setting["minResolution"] {
            self.minResolution = sMinResolution as? String
        }
        if let sMinFramerate = setting["minFramerate"] {
            self.minFramerate = sMinFramerate as? Int
        }
        if let sMinBitrate = setting["minBitrate"] {
            self.minBitrate = sMinBitrate as? Int
        }
        if let sCurrentResolution = setting["currentResolution"] {
            self.currentResolution = sCurrentResolution as? String
        }
        if let sCurrentFramerate = setting["currentFramerate"] {
            self.currentFramerate = sCurrentFramerate as? Int
        }
        if let sCurrentBitrate = setting["currentBitrate"] {
            self.currentBitrate = sCurrentBitrate as? Int
        }

        
    }
}