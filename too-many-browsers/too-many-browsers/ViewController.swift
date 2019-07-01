import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = CommandLine.arguments[1]
        shell(cmd:"/usr/bin/open", args:["-a", "Safari", url])
        shell(cmd:"/usr/bin/open", args:["-a", "Firefox", url])
        shell(cmd:"/usr/bin/open", args:["-a", "Google Chrome", url])
        
        let escapedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        shell(cmd:"/usr/bin/open", args:["-a", "Google Chrome", "https://live.browserstack.com/dashboard#os=Windows&os_version=10&browser=Edge&browser_version=18.0&resolution=responsive-mode&url=\(escapedUrl)&speed=1&start=true"])

        let simUUID = "D981E546-816B-47BB-8318-12F10FC59362"
        shell(cmd:"/usr/bin/xcrun", args:["simctl", "boot", simUUID])
        shell(cmd: "/usr/bin/open", args:["/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/"])
        shell(cmd:"/usr/bin/xcrun", args: ["simctl", "openurl", simUUID, url])
    }
    
    func shell(cmd: String, args: [String]) -> String
    {
        let task = Process()
        task.launchPath = cmd
        task.arguments = args
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: String.Encoding.utf8)!
    }

}

