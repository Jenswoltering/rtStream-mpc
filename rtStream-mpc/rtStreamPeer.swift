//
//  rtStreamPeer.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 02.02.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class rtStreamPeer {
    var peerID:MCPeerID
    var name:String
    var isBroadcaster:Bool?
    
    init(peerID:MCPeerID, isBroadcaster:Bool){
        self.peerID = peerID
        self.name = peerID.displayName
        self.isBroadcaster = isBroadcaster
    }
}