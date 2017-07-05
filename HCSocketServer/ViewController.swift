//
//  ViewController.swift
//  HCSocketServer
//
//  Created by UltraPower on 2017/7/4.
//  Copyright © 2017年 UltraPower. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var clientText: NSTextView!
    @IBOutlet weak var connectStatus: NSTextField!
    @IBOutlet weak var message: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        HCSocketServer.socketServer(address: "172.16.40.33", port: 8888)
            .start { (_, status) in
                switch status {
                case let .listen(_, info):
                    self.connectStatus.stringValue = info
                default:
                    break
                }
            }
            .accept { (client, status) in
                DispatchQueue.main.async {
                    switch status {
                    case let .connect(_, info),let .other(false, info),let .read(false, info):
                        self.connectStatus.stringValue = info
                    case let .read(true, info):
                        self.clientText.string =  (self.clientText.string ?? "") + "\nFriend:" + info
                    default:
                        break
                    }
                }
        }
        
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func replyAction(_ sender: NSButton) {
        if message.stringValue.characters.count == 0 {
            return
        }
        HCSocketServer.socketServerManager.reply(message: message.stringValue) { (client, status) in
            switch status {
            case let .send(false, info):
                self.connectStatus.stringValue = info
            case .send(true, _):
                self.clientText.string = (self.clientText.string ?? "") + "\nME:" + self.message.stringValue
                self.message.stringValue = ""
            default:
                break
            }
        }
    }
    
}

