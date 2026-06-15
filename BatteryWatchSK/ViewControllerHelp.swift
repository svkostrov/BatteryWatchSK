//
//  ViewControllerHelp.swift
//  BatteryWatchSK
//
//  Created by Сергей Костров on 17.02.2021.
//  Copyright © 2021 Сергей Костров. All rights reserved.
//

import UIKit

class ViewControllerHelp: UIViewController {

    
    @IBOutlet weak var Version: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let VersionBundle = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            Version.text = "ver: " + VersionBundle
                }
    }
    

    

}
