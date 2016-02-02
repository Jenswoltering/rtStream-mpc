//
//  rtStream.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 26.01.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class RTStream{
    var mcManager:MCManager!
    var controlChanel:ControlChanelManager!
    
    var connectedPeers:[rtStreamPeer]=[]
    
    init(serviceType:String){
        mcManager=MCManager(serviceTyeName: serviceType)
        controlChanel=ControlChanelManager(parent: self, transportManager: mcManager)
        mcManager.delegate=controlChanel
        sleep(5)
        mcManager.startBrowsing()
    }
    
    func addPeer(connectedPeer:MCPeerID, isBroacaster:Bool){
        let newPeer=rtStreamPeer(peerID: connectedPeer, isBroadcaster: isBroacaster)
        self.connectedPeers.append(newPeer)
    }
    
    func deletePeer(lostPeer:MCPeerID){
        if connectedPeers.isEmpty == false {
            for (index,peer) in connectedPeers.enumerate(){
                if peer.name == lostPeer.displayName{
                    connectedPeers.removeAtIndex(index)
                }
            }
        }
        
        self.connectedPeers = self.connectedPeers.filter({$0 !== lostPeer})
    }
}
