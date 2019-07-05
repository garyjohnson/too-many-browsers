import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    var observers = [NSKeyValueObservation]()
    var bundleIds = [
        "Safari": "com.apple.Safari",
        "Firefox": "org.mozilla.firefox",
        "Google Chrome": "com.google.Chrome",
    ]
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem.menu = statusMenu
        statusItem.button!.image = NSImage(named: "status-icon")
        
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("Access Not Enabled")
        } else {
            print("Access Enabled")
        }
        
        self.observers = [
            NSWorkspace.shared.observe(\.runningApplications, options: [.initial]) {(model, change) in
                if(change.kind == NSKeyValueChange.insertion){
                    change.indexes?.forEach {
                        let newApp = NSWorkspace.shared.runningApplications[$0]
                        if(newApp.bundleIdentifier == self.bundleIds["Safari"]!) {

                            sleep(1)
                            let appRef = AXUIElementCreateApplication(newApp.processIdentifier);
                            var value: AnyObject?
                            let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &value)
                            
                            if let windowList = value as? [AXUIElement] {
                                print ("windowList #\(windowList)")
                                if let window = windowList.first
                                {
                                    var position : CFTypeRef
                                    var size : CFTypeRef
                                    var  newPoint = CGPoint(x: 0, y: 0)
                                    var newSize = CGSize(width: 200, height: 200)
                                    
                                    position = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!,&newPoint)!;
                                    AXUIElementSetAttributeValue(windowList.first!, kAXPositionAttribute as CFString, position);
                                    
                                    size = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!,&newSize)!;
                                    AXUIElementSetAttributeValue(windowList.first!, kAXSizeAttribute as CFString, size);
                                }
                            }
                        }
                    }
                }
            }
        ]
        
        let url = "http://www.bing.com"
        launchAndCaptureWindow(url: url)
        
        //launchItAll(url: url)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
    }
    func launchAndCaptureWindow(url: String) {
        let bundleId:String = bundleIds["Safari"]!
        let previousPids = NSWorkspace.shared.runningApplications.filter { $0.bundleIdentifier == bundleId }.map { $0.processIdentifier }
        shell(cmd:"/usr/bin/open", args:["-n", "-b", bundleId, url])
        //let newPids = NSWorkspace.shared.runningApplications.filter { $0.bundleIdentifier == bundleId }.map { $0.processIdentifier }
        
        //let ourPids = newPids.filter { !previousPids.contains($0) }
        //let ourApp = NSRunningApplication.init(processIdentifier: ourPids[0])
    }
    
    func launchItAll(url: String) {
        shell(cmd:"/usr/bin/open", args:["-n", "-a", "Safari", url])
        shell(cmd:"/usr/bin/open", args:["-n", "-a", "Firefox", url])
        shell(cmd:"/usr/bin/open", args:["-n", "-a", "Google Chrome", url])
        
        let escapedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        shell(cmd:"/usr/bin/open", args:["-n", "-a", "Google Chrome", "https://live.browserstack.com/dashboard#os=Windows&os_version=10&browser=Edge&browser_version=18.0&resolution=responsive-mode&url=\(escapedUrl)&speed=1&start=true"])
        
        let simUUID = "D981E546-816B-47BB-8318-12F10FC59362"
        shell(cmd:"/usr/bin/xcrun", args:["simctl", "boot", simUUID])
        shell(cmd: "/usr/bin/open", args:["/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/"])
        shell(cmd:"/usr/bin/xcrun", args: ["simctl", "openurl", simUUID, url])
    }

    @IBAction func onQuitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    func shell(cmd: String, args: [String]) -> Int32
    {
        let task = Process()
        task.launchPath = cmd
        task.arguments = args
    
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output =  String(data: data, encoding: String.Encoding.utf8)!
        NSLog(output);
        
        return task.processIdentifier
    }
}
