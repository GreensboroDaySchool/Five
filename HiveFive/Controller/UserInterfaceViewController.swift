//
//  UserInterfaceViewController.swift
//  Hive Five
//
//  Created by Jiachen Ren on 4/6/18.
//  Copyright © 2018 Greensboro Day School. All rights reserved.
//

import UIKit

class UserInterfaceViewController: UIViewController {

    @IBOutlet weak var tabBarVisibilitySwitch: UISwitch!
    @IBOutlet weak var preferredNodeSizeSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tabBarVisibilitySwitch.isOn = toolBarShouldBeVisible()
        preferredNodeSizeSegmentedControl.selectedSegmentIndex = nodeSizeIndex()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tabBarVisibilitySwitchToggled(_ sender: UISwitch) {
        let isOn = sender.isOn
        save(id: toolBarVisibilityId, obj: isOn)
        post(name: toolBarVisibilityNotification, object: isOn)
    }
    
    private func post(name: NSNotification.Name, object: Any?) {
        NotificationCenter.default.post(name: name, object: object, userInfo: nil)
    }
    
    @IBAction func preferredNodeSizeSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        save(id: preferredNodeSizeId, obj: index)
        post(name: preferredNodeSizeNotification, object: index)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}