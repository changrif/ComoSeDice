//
//  SettingsViewController.swift
//  comosedice
//
//  Created by Chandler Griffin on 10/29/17.
//  Copyright © 2017 Chandler Griffin. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var languagePicker: UIPickerView!
    @IBOutlet weak var labelColorSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        languagePicker.dataSource = self;
        languagePicker.delegate = self;
        
        let defaults = UserDefaults.standard
        
        labelColorSwitch.setOn(defaults.bool(forKey: "color"), animated: true)
        languagePicker.selectRow(defaults.integer(forKey: "language"), inComponent: 0, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languages().count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return languages()[row]["name"]
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveSettings(_ sender: Any) {
        let defaults = UserDefaults.standard
        let row = languagePicker.selectedRow(inComponent: 0)
        
        defaults.set(labelColorSwitch.isOn, forKey: "color")
        defaults.set(row, forKey: "language")
        defaults.set(languages()[row]["code"], forKey: "code")
        defaults.synchronize()
        
        dismiss(animated: true, completion: nil)
    }
    
    func languages() -> [[String:String]] {
        return [["name" : "Arabic", "code": "ar"],
                ["name" : "Chinese (Traditional)", "code": "zh-TW"],
                ["name" : "French", "code": "fr"],
                ["name" : "German", "code": "de"],
                ["name" : "Hindi", "code": "hi"],
                ["name" : "Italian", "code": "it"],
                ["name" : "Japanese", "code": "ja"],
                ["name" : "Spanish", "code": "es"],
                ["name" : "Tagalog", "code": "tl"]]
        }
}
