//
//  PlayerViewController.swift
//  rtStream-mpc
//
//  Created by Jens Woltering on 08.02.16.
//  Copyright © 2016 Jens Woltering. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController {
    var navtitle :String?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = self.navtitle
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
