//
//  SettingsTableViewController.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 06.02.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var minFramerateLabel: UILabel!
    @IBOutlet weak var framerateSlider: UISlider!
    @IBOutlet weak var changeFramerateSlider: UISlider!
    @IBOutlet weak var selectedResolutionLabel: UILabel!
    @IBOutlet weak var changeResolutionStepper: UIStepper!
    @IBOutlet weak var advertiseDeviceSwitch: UISwitch!
    @IBOutlet weak var isBroadcasting: UISwitch!
    @IBOutlet weak var displaynameTextfield: UITextField!
    @IBOutlet weak var resolutionSlider: UISlider!
    @IBOutlet weak var minBitrateLabel: UILabel!
    @IBOutlet weak var changeBitrateSlider: UISlider!
    
        override func viewDidLoad() {
            super.viewDidLoad()
            displaynameTextfield.delegate = self
            displaynameTextfield.userInteractionEnabled=true
            displaynameTextfield.text=RTStream.sharedInstance.myPeer?.name
            changeBitrateSlider.value = Float((RTStream.sharedInstance.myPeer?.minBitrate)!)
            changeFramerateSlider.value = Float((RTStream.sharedInstance.myPeer?.minFramerate)!)
            minFramerateLabel.text = changeFramerateSlider.value.description
            minBitrateLabel.text = changeBitrateSlider.value.description
            changeResolutionStepper.maximumValue = Double(RTStream.possibleResolutions.count)
            
            
            //find the current resolution value and set the stepper value
            for possibleResolution in RTStream.possibleResolutions{
                if possibleResolution.key == RTStream.sharedInstance.myPeer?.currentResolution! {
                    changeResolutionStepper.value = Double(possibleResolution.value)
                }
            }
            selectedResolutionLabel.text =  RTStream.possibleResolutions[Int(changeResolutionStepper.value)-1].key
            advertiseDeviceSwitch.addTarget(self, action: "advertiseDeviceValueChanged", forControlEvents: UIControlEvents.ValueChanged)
            isBroadcasting.addTarget(self, action: "isBroadcastingValueChanged", forControlEvents: UIControlEvents.ValueChanged)
            changeResolutionStepper.addTarget(self, action: "changeResolutionStepperValueChanged", forControlEvents: UIControlEvents.ValueChanged)
            
            if isBroadcasting.on {
                RTStream.sharedInstance.myPeer?.isBroadcaster = true
                RTStream.sharedInstance.startBroadcasting()
            }else{
                RTStream.sharedInstance.myPeer?.isBroadcaster = false
                RTStream.sharedInstance.stopBroadcasting()
            }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    @IBAction func changeBitrateSliderValueChanged(sender: AnyObject) {
        let newValue = Int(roundf(changeBitrateSlider.value / 250) * 250)
        changeBitrateSlider.setValue(Float(newValue), animated: false)
        minBitrateLabel.text = changeBitrateSlider.value.description
        RTStream.sharedInstance.minBitrate = Int(changeBitrateSlider.value)
    }
    
    @IBAction func framerateSliderValueChanged(sender: AnyObject) {
        let newValue = Int(changeFramerateSlider.value / 30 * 30)
        changeFramerateSlider.setValue(Float(newValue), animated: false)
        minFramerateLabel.text = changeFramerateSlider.value.description
        RTStream.sharedInstance.myPeer?.minFramerate = Int (changeFramerateSlider.value)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        displaynameTextfield.resignFirstResponder()
        RTStream.sharedInstance.myPeer?.name = displaynameTextfield.text!
        return true
    }

    func advertiseDeviceValueChanged(){
        
        if advertiseDeviceSwitch.on {
            RTStream.sharedInstance.startBrowsing()
        }else{
            RTStream.sharedInstance.stopBrowsing()
        }
        
    }
    
    
    func changeResolutionStepperValueChanged(){
        selectedResolutionLabel.text =  RTStream.possibleResolutions[Int(changeResolutionStepper.value)-1].key
        RTStream.sharedInstance.myPeer?.minResolution = RTStream.possibleResolutions[Int(changeResolutionStepper.value)-1].key

    }
    
    func isBroadcastingValueChanged(){
        
        if isBroadcasting.on {
            RTStream.sharedInstance.myPeer?.isBroadcaster = true
            RTStream.sharedInstance.startBroadcasting()
        }else{
            RTStream.sharedInstance.myPeer?.isBroadcaster = false
            RTStream.sharedInstance.stopBroadcasting()
        }

    }

    // MARK: - Table view data source

//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 2
//    }

//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 2
//    }

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

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
