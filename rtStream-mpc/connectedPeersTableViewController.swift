//
//  connectedPeersTableViewController.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 03.02.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import UIKit

class connectedPeersTableViewController: UITableViewController {

 
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
            return RTStream.sharedInstance.getConnectedPeers().count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var peer :rtStreamPeer?
        let cell = tableView.dequeueReusableCellWithIdentifier("PeerCell", forIndexPath: indexPath)
        peer = RTStream.sharedInstance.getConnectedPeers()[indexPath.row]
        
        cell.textLabel?.text = peer!.name
        if peer!.isBroadcaster == true {
            cell.detailTextLabel?.text = "broadcasting"
        }else{
            cell.detailTextLabel?.text = "receiver"
            cell.accessoryType=UITableViewCellAccessoryType.None
        }
       

        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Player"{
            let cell = sender as! UITableViewCell
            let navTitle = cell.textLabel?.text
            
            let controller = segue.destinationViewController as! DisplayLayerViewController
            controller.navtitle = navTitle
            var peerForSegue :rtStreamPeer?
            for peer in RTStream.sharedInstance.getConnectedPeers() {
                if peer.name == cell.textLabel?.text{
                    peerForSegue = peer
                }
            }
            controller.peerToDisplay = peerForSegue!
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
