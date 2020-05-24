//
//  utilities.swift
//

import Foundation

func fileExists(at: URL) -> Bool {
    return fileExists(at: at.path)
}

func fileExists(at: String) -> Bool {
    
    var isDirectory: ObjCBool = false
    if !FileManager.default.fileExists(atPath: at, isDirectory: &isDirectory) || isDirectory.boolValue {
        return false
    } else {
        return true
    }
    
}

func directoryExists(at: URL) -> Bool {
    return directoryExists(at: at.path)
}

func directoryExists(at: String) -> Bool {
    
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: at, isDirectory: &isDirectory) && isDirectory.boolValue {
        return true
    } else {
        return false
    }
    
}

func isReadable(at: URL) -> Bool {
    return isReadable(at: at.path)
}

func isReadable(at: String) -> Bool {
    return FileManager.default.isReadableFile(atPath: at)
}

func isWritable(at: URL) -> Bool {
    return isWritable(at: at.path)
}

func isWritable(at: String) -> Bool {
    return FileManager.default.isWritableFile(atPath: at)
}

func printDuration(msg: String, start: Date) {
    
    print("\(msg) \(round(start.timeIntervalSinceNow * -1000000)/1000) ms")
    
}

func appleScriptSource(file: String, verbose: Bool) throws -> String {
    
    var compiledFile = ""
    var start: Date
    
    
    if file.hasSuffix(".applescript") {
        
        var scriptId = file
        scriptId.removeLast(12)
        scriptId = scriptId.replacingOccurrences(of: "/", with: "_")
        scriptId = scriptId.replacingOccurrences(of: ":", with: "-")
        scriptId = scriptId.replacingOccurrences(of: ".", with: "-")
        scriptId = scriptId.replacingOccurrences(of: " ", with: "-")
        
        compiledFile = temporaryDirectory() + "\(scriptId).scpt"
        
        start = Date()
        
        let (_, error, status) = shell(cmd: "/usr/bin/osacompile", args: ["-o", compiledFile, file])
        if status != 0 {
            throw AppleScriptReadError("\(error)")
        }
        
        if verbose { printDuration(msg: "Compiled in", start: start) }
        
    } else {
        
        print("Input file already compiled")
        compiledFile = file
        
    }
    
    start = Date()
    
    let (output, error, status) = shell(cmd: "/usr/bin/osadecompile", args: [compiledFile])
    if status != 0 {
        throw AppleScriptReadError("\(error)")
    }
    
    if verbose { printDuration(msg: "Decompiled in", start: start) }
    
    return output

}

func userDesktopDirectory() -> String {
    
    let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
    let userDesktopDirectory = paths[0]
    return userDesktopDirectory + "/"
    
}

func temporaryDirectory() -> String {
    
    return NSTemporaryDirectory() as String
    
}

func shell(cmd : String, args : [String]) -> (output: String, error: String, exitCode: Int32) {

    var output = ""
    var error = ""

    let task = Process()
    task.executableURL = URL(fileURLWithPath: cmd)
    task.arguments = args

    let outpipe = Pipe()
    task.standardOutput = outpipe
    let errpipe = Pipe()
    task.standardError = errpipe

    task.launch()

    let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
    if let string = String(data: outdata, encoding: .utf8) {
        output = string
    }

    let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
    if let string = String(data: errdata, encoding: .utf8) {
        error = string
    }

    task.waitUntilExit()
    
    return (output, error, task.terminationStatus)
    
}

func convertToHTMLHeaderId(_ str: String) -> String {
    
    let allowedSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789- ")
    
    let modifiedString = String(str.lowercased()
        .unicodeScalars.filter { allowedSet.contains($0) }
    ).replacingOccurrences(of: " ", with: "-")
    
    return modifiedString
    
}

func patternCount(string: String, pattern: String) -> Int {
    
    return string.components(separatedBy: pattern).count - 1
    
}
