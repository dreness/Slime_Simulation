//
//  ViewController.swift
//  Slime_simulation
//
//  Created by Edo Vay on 22/12/21.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var MainView: MainView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown, handler: {(evt: NSEvent!) -> NSEvent in
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown, handler: {(evt: NSEvent!) -> NSEvent? in

            NSLog("Local Keydown: " + evt.characters! + " (" + String(evt.keyCode) + ")");
            // h
            
            switch evt.keyCode {
            case 4:
                self.MainView.updateUIVisibility = true
                return nil
            case 32:
                self.MainView.btnUpdate(self.MainView.updateButton)
                return nil
            default:
                return evt
            }
        })
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

