//
//  MCManager.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 25.01.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import CoreMedia

protocol MCManagerDelegate {
    
    func connectedDevicesChanged(manager : MCManager, connectedDevice: MCPeerID, didChangeState: Int)
    func lostPeer(manager : MCManager, lostDevice: MCPeerID)
    func incomingMassage(manager : MCManager, fromPeer : MCPeerID, msg: NSData)
    
}

class MCManager: NSObject ,MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate {
    private let serviceType:String?
    private let myPeerId = MCPeerID(displayName: UIDevice.currentDevice().name.capitalizedString)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    let serviceBrowser: MCNearbyServiceBrowser
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
        session.delegate = self
        return session
    }()
    
  

    var delegate : MCManagerDelegate?
    
    convenience override init() {
        self.init(serviceTyeName: "rtStream")
        
        
    }
    
    init(serviceTyeName:String) {
        self.serviceType=serviceTyeName
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType!)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType!)
        super.init()
        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
       
    }
    
    func getMyPeerID()->MCPeerID{
        return self.myPeerId
    }
    
    func startBrowsing(){
        self.serviceAdvertiser.startAdvertisingPeer()
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    
    func stopBrowsing(){
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
     // MARK: - MCNearbyServiceAdvertiserDelegate Methods
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print("\(error) : didNotStartAdvertisingPeer")
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        print("\(peerID) : didReceiveInvitationFromPeer")
        invitationHandler(true, self.session)
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate Methods
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print("\(error) didNotStartBrowsingForPeers")
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("\(peerID) : lostPeer:")
        self.delegate?.lostPeer(self, lostDevice:  peerID)
    }
    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("\(peerID) : foundPeer")
        self.serviceBrowser.invitePeer(peerID, toSession: self.session, withContext: nil, timeout: 10)
    }
    
    
    
    // MARK: - MCSessionDelegate Methods
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        switch state {
        case .NotConnected:
             print("not connected")
        case .Connected:
             print("connected")
             if session.connectedPeers.contains(peerID){
                self.delegate?.connectedDevicesChanged(self ,connectedDevice: peerID, didChangeState: state.rawValue)
             }
        default:
             print("connecting")
        }
        //NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue.description)")
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        //print("didReceiveData:")
        NSLog("Dateigröße: " + data.length.description)
        
        
        
        self.delegate?.incomingMassage(self, fromPeer: peerID, msg: data)
        
        
        
       
            
        
        
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        RTStream.sharedInstance.inStream = Stream(inputStream: stream, outputStream: nil)
        
        print("\(streamName) : didReceiveStream")
        
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        print("\(resourceName) : didFinishReceivingResourceWithName")
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        print("\(resourceName) : didStarReceivingResourceWithName")
    }
    
    func sendMessageToPeer(peer: MCPeerID, messageToSend message:NSData) ->Bool{
        var toPeer:[MCPeerID]=[]
        toPeer.append(peer)
        do{
            try self.session.sendData(message, toPeers: toPeer, withMode: MCSessionSendDataMode.Unreliable)
            return true
        }catch{
            return false
        }
    }
    
    
}





