//
//  ViewController.swift
//  LoLChatFixLauncher
//
//  Created by SunYeop Lee on 2015. 8. 31..
//  Copyright © 2015년 SunYeop Lee. All rights reserved.
//

import Cocoa

let LOLCHATFIX_BASE_URL = "http://lolchatfix.funso.me"

class ViewController: NSViewController {
    
    @IBOutlet weak var pathLoLApp: NSPathControl!
    @IBOutlet weak var lblCurrentPluginVersion: NSTextField!
    @IBOutlet weak var lblLatestPluginVersion: NSTextField!
    
    @IBAction func onPathLoLAppChanged(sender: AnyObject) {
        if let path = pathLoLApp.URL?.path {
            let def: NSUserDefaults = NSUserDefaults.standardUserDefaults()
            
            if path == "/Applications/League of Legends.app" {
                def.removeObjectForKey("LoLAppPath")
            } else {
                def.setObject(path, forKey: "LoLAppPath")
            }
            
            def.synchronize()
            
            NSThread.detachNewThreadSelector("updateLblCurrentExecutableCksum", toTarget: self, withObject: nil)
        }
    }
    
    func getPluginPath() -> String {
        return NSBundle.mainBundle().bundlePath + "/Contents/MacOS/libLoLChatFix.dylib"
    }
    
    func updateLblLatestPluginVersion() {
        let task: NSTask = NSTask()
        let pipe: NSPipe = NSPipe()
        
        task.launchPath = "/usr/bin/curl"
        task.arguments = [LOLCHATFIX_BASE_URL + "/latest_version"]
        task.standardOutput = pipe
        task.standardError = nil
        task.launch()
        task.waitUntilExit()
        
        let readData = pipe.fileHandleForReading.readDataToEndOfFile()
        let readString = NSString(data: readData, encoding: NSUTF8StringEncoding)
        
        if let latest_version = readString?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) {
            dispatch_async(dispatch_get_main_queue(), {
                self.lblLatestPluginVersion.stringValue = latest_version
                
                var color: NSColor?
                
                if let cl = NSColorList(named: "Crayons") {
                    if self.lblCurrentPluginVersion.stringValue != latest_version {
                        color = cl.colorWithKey("Maraschino")
                    } else {
                        color = cl.colorWithKey("Clover")
                    }
                }
                
                if color != nil {
                    self.lblCurrentPluginVersion.textColor = color!
                }
            })
        }
    }
    
    /*
    func updateLblCurrentExecutableCksum() {
        if let lolPath = pathLoLApp.URL?.path {
            let searchPath = lolPath + "/Contents/LoL/RADS/solutions/lol_game_client_sln/releases/"
            let fileManager = NSFileManager()
            
            do {
                let dirContents = try fileManager.contentsOfDirectoryAtPath(searchPath)
                
                for content in dirContents {
                    let task: NSTask = NSTask()
                    let pipe: NSPipe = NSPipe()
                    
                    task.launchPath = "/usr/bin/cksum"
                    task.arguments = [searchPath + content + "/deploy/LeagueofLegends.app/Contents/MacOS/LeagueofLegends"]
                    task.standardOutput = pipe
                    task.launch()
                    task.waitUntilExit()
                    
                    if task.terminationStatus == 0 {
                        let readData = pipe.fileHandleForReading.readDataToEndOfFile()
                        let readString = NSString(data: readData, encoding: NSUTF8StringEncoding)
                        
                        if let cksum = readString?.componentsSeparatedByString(" ")[0] {
                            dispatch_async(dispatch_get_main_queue(), {
                                self.lblCurrentBinaryCksum.stringValue = cksum as String
                            })
                            
                            if self.lblTargetBinaryCksum.stringValue == cksum {
                                dispatch_async(dispatch_get_main_queue(), {
                                    if let color = NSColorList(named: "Crayons")?.colorWithKey("Clover") {
                                        self.lblTargetBinaryCksum.textColor = color
                                    }
                                })
                            } else {
                                dispatch_async(dispatch_get_main_queue(), {
                                    if let color = NSColorList(named: "Crayons")?.colorWithKey("Maraschino") {
                                        self.lblTargetBinaryCksum.textColor = color
                                    }
                                })
                            }
                            
                            return
                        }
                    }
                    
                    break
                }
            } catch {
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self.lblCurrentBinaryCksum.stringValue = "(실패)"
            
            if let color = NSColorList(named: "Crayons")?.colorWithKey("Maraschino") {
                self.lblTargetBinaryCksum.textColor = color
            }
        })
    }
    */
    
    func updatePlugin() {
        let task: NSTask = NSTask()
        
        task.launchPath = "/usr/bin/curl"
        task.arguments = ["-o", getPluginPath(), LOLCHATFIX_BASE_URL + "/libLoLChatFix.dylib"]
        task.launch()
        task.waitUntilExit()
        
        dispatch_async(dispatch_get_main_queue(), {
            self.refreshMainUI()
            
            if task.terminationStatus != 0 {
                let alert: NSAlert = NSAlert()
                alert.messageText = "업데이트 실패"
                alert.informativeText = NSString(format: "알 수 없는 오류로 업데이트에 실패하였습니다. (오류 코드: %d)", task.terminationStatus) as String
                alert.runModal()
            }
        })
    }
    
    @IBAction func updateButtonPressed(sender: AnyObject) {
        NSThread.detachNewThreadSelector("updatePlugin", toTarget: self, withObject: nil)
    }
    
    @IBAction func gameStartButtonPressed(sender: AnyObject) {
        /*
        if lblTargetBinaryCksum.stringValue != lblCurrentBinaryCksum.stringValue {
            let alert: NSAlert = NSAlert()
            alert.messageText = "체크섬 불일치"
            alert.informativeText = "바이너리 체크섬이 일치하지 않습니다. 이는 충돌을 유발할 수 있습니다. 그래도 실행하시겠습니까?"
            ahhlert.addButtonWithTitle("No")
            alert.addButtonWithTitle("Yes")
            
            switch(alert.runModal()) {
            case NSAlertFirstButtonReturn:
                return;
            default:
                break
            }
        }
        */
    
        let task: NSTask = NSTask()
        
        if let lolPath = pathLoLApp.URL?.path {
            var env = NSProcessInfo.processInfo().environment
            env["DYLD_INSERT_LIBRARIES"] = getPluginPath()
            
            task.launchPath = lolPath + "/Contents/MacOS/RiotMacContainer"
            task.environment = env
        
            if NSFileManager.defaultManager().isExecutableFileAtPath(task.launchPath!) == true {
                task.launch()
                return
            }
        }
        
        NSLog("An error has occurred. Check LoLPath")
    }
    
    func refreshMainUI() {
        let def: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        if let lolAppPath = def.stringForKey("LoLAppPath") {
            pathLoLApp.URL = NSURL(fileURLWithPath: lolAppPath)
        }
        
        let handle = dlopen(getPluginPath(), RTLD_NOW)
        
        if let plugin_version = String.fromCString(UnsafePointer<CChar>(dlsym(handle, "plugin_version"))) {
            lblCurrentPluginVersion.stringValue = plugin_version
            
            /*
            let target_checksum = UnsafePointer<UInt32>(dlsym(handle, "target_checksum")).memory
            lblTargetBinaryCksum.stringValue = NSString(format: "%u", target_checksum) as String
            */
        }
        
        dlclose(handle)
        
        NSThread.detachNewThreadSelector("updateLblLatestPluginVersion", toTarget: self, withObject: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshMainUI()
    }
}

