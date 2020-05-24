//
//  Script.swift
//

import Foundation

class ScriptDocument {
    
    let headingMarker = "________________________________"
    
    let source: String
    let name : String
    let blobURLPrefix : String?
    let verbose : Bool
    
    var lines : [ScriptLine] = []
    var comments : [Int: ScriptComment] = [:]
    var strings : [Int: [ScriptString]] = [:]
    
    var stack : [ScriptLine] = []
    
    var children : [ScriptLine] = []
    var docLines : [String] = []
    
    init(withSource source: String, name: String, blobURLPrefix: String?, verbose: Bool) {
        
        // Initialize a new ScriptDocument
        self.source = source
        self.name = name
        self.blobURLPrefix = blobURLPrefix
        self.verbose = verbose
        
    }
    
    func writeDocumentation(to: String) throws {
        
        var start: Date?
        
        if verbose {
            print("Parsing source")
            start = Date()
        }
        
        parse()
        
        if verbose { printDuration(msg: "Parsed in", start: start!) }
            
        if verbose {
            print("Generating documentation")
            start = Date()
        }
        
        let doc = generateDocumentation()
        
        if verbose { printDuration(msg: "Generated in", start: start!) }
        
        if verbose {
            print("Writing to file")
            start = Date()
        }
        
        try doc.write(to: URL(fileURLWithPath: to), atomically: true, encoding: String.Encoding.utf8)
        
        if verbose { printDuration(msg: "Wrote in", start: start!) }
        
    }
    
    func currentPath() -> String {
        
        var path = "/"
        
        for line in stack {
            path += "\(line.name())/"
        }
        
        return path
    }
    
    func printCurrentPath() {
      
        print("Path: \(currentPath())")
        
    }
    
    func addToStack(_ line: ScriptLine) {
        stack.append(line)
    }
    
    func removeFromTopOfStack(_ line: ScriptLine) {
        
        if let top = stack.last {
            if top.number == line.number {
                stack.removeLast()
            }
        }
        
    }
    
    func islastDocLineEmpty() -> Bool {
        
        if let lastDocLine = docLines.last {
            return lastDocLine.isEmpty
        } else {
            return true;
        }
        
    }
    
    func add(_ str: String) {
        
        if str.contains("\n") {
            
            let strComponents = str.components(separatedBy: "\n")
            for strComponent in strComponents {
                
                add(strComponent)
                
            }
            
        } else {
            
            if verbose {
                print("Line \(docLines.count + 1): \(str)")
            }
            docLines.append(str)
            
        }
    }
    
    func addBlank() {
        add("")
    }
    
    func addBlankIfNecessary() {
        if !islastDocLineEmpty() {
            addBlank()
        }
    }
    
    func findOverviewComment() -> String {
        
        var overviewComment: String = ""
        
        for child in children {
            
            if !child.isBlank() {
                
                if let comment = comments[child.number] {
                    overviewComment = comment.content()
                }
                break
            }
           
        }
        
        return overviewComment
        
    }
    
    func generateDocumentation() -> String {
        
        docLines = []
    
        add("# \(name)")
        
        let overviewComment = findOverviewComment()
        
        // Add table of contents
        addBlankIfNecessary()
        add("## Contents")
        addBlank()
        
        if !overviewComment.isEmpty {
            // Add overview to table of contents
            add("- [Overview](#overview)")
        }
        
        // Add table of contents for direct children; this will skip any scripts
        for child in children {
             if child.isHeadingStart || child.isFunctionStart {
                child.generateTableOfContents(depthOffset: 0)
             }
        }
        
        // Add table of contents for every script found anywhere
        for line in lines {
            if line.isScriptStart {
                line.generateTableOfContents(depthOffset: line.depth * -1)
            }
        }
        
        if !overviewComment.isEmpty {
            addBlankIfNecessary()
            add("## Overview")
            addBlank()
            add(overviewComment)
        }
        
        addBlankIfNecessary()
        
        for child in children {
            if child.isHeadingStart || child.isFunctionStart {
               child.generateDocumentation(depthOffset: 2)
            }
        }
        
        for line in lines {
            if line.isScriptStart {
                line.generateDocumentation(depthOffset: line.depth * -1 + 2)
            }
        }
        
        return docLines.joined(separator: "\n")
        
    }
    
    func parse() {
        
        initLines()
        
        if verbose { print("Found \(lines.count) line(s)") }
        
        initHierarchy()
        
    }
    
    func initLines() {
        
        if verbose { print("Initializing lines") }
        
        let chars = Array(source)
        var charIndex = 0
        var lineCharIndex = 0
        let charCount = chars.count
        var stopCountingIndentation = false
        var indentationBuffer = ""
        
        var lineIndex = 0
        var lineNumber = 1
        var lineBuffer = ""
        
        var inString = false
        var stringJustStarted = false
        var stringBuffer = ""
        var stringStartLineIndex = 0
        
        var inComment = false
        var commentBuffer = ""
        
        var inCommentBlock = false
        var commentBlockJustEnded = false
        var commentBlockBuffer = ""
        var commentBlockStartLineIndex = 0
        
        var isEscaped = false
        
        var c : Character = Array("a")[0]
        var c2 : Character?
        
        while charIndex < charCount {
             
            c = chars[charIndex]
            
            if charIndex + 1 < charCount {
                c2 = chars[charIndex + 1]
            } else {
                c2 = nil
            }
            
            if inString && !isEscaped && c.asciiValue == 92 { // 92: Backslash
                
                if verbose { print("Line \(lineNumber): Found backslash at character \(charIndex)" ) }
                
                stringBuffer += String(c)
                isEscaped = true
                
            } else {
                
                if inString {
                    
                    if c.asciiValue == 34 && !isEscaped { // 34: Quotation mark
                        
                        if verbose { print("Line \(lineNumber): Found end of string \"\(stringBuffer.replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\t", with: "\\t"))\" at character \(charIndex)" ) }
                        
                        if strings[stringStartLineIndex + 1] == nil {
                            strings[stringStartLineIndex + 1] = []
                        }
                        
                        strings[stringStartLineIndex + 1]!.append(ScriptString(
                            document: self,
                            lineNumber: stringStartLineIndex + 1,
                            scriptOffset: charIndex,
                            lineOffset: lineCharIndex,
                            text: stringBuffer
                        ))
                        
                        stringBuffer = ""
                        inString = false
                    }
                    
                } else if inComment {
                    
                    if c.asciiValue == 10 { // 10: New line
                        
                        if verbose { print("Line \(lineNumber): Found end of comment \"\(commentBuffer)\" at character \(charIndex)" ) }
                        
                        comments[lineNumber] = ScriptComment(
                            document: self,
                            lineNumber: lineNumber,
                            scriptOffset: charIndex,
                            lineOffset: lineCharIndex,
                            text: commentBuffer,
                            isBlock: false
                        )
                        
                        commentBuffer = ""
                        inComment = false
                        
                    }
                    
                } else if inCommentBlock {
                    
                    if c.asciiValue == 42 && c2?.asciiValue == 41 { // 42: Asterisk, 41: Closing parentheses
                        
                        commentBlockBuffer = "\(commentBlockBuffer)*)"
                        
                        if verbose { print("Line \(lineNumber): Found end of comment block \"\(commentBlockBuffer.replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\t", with: "\\t"))\" at character \(charIndex)" ) }
                        
                        comments[commentBlockStartLineIndex + 1] = ScriptComment(
                            document: self,
                            lineNumber: commentBlockStartLineIndex + 1,
                            scriptOffset: charIndex,
                            lineOffset: lineCharIndex,
                            text: commentBlockBuffer,
                            isBlock: true
                        )
                        
                        commentBlockBuffer = ""
                        commentBlockJustEnded = true
                        inCommentBlock = false
                        charIndex += 1
                        lineCharIndex += 1
                        
                    }
                    
                } else if c2 != nil && c.asciiValue == 34 { // 34: Quotation mark
                    
                    if c2!.asciiValue == 34 {
                        
                        if verbose { print("Line \(lineNumber): Found empty string at character \(charIndex)" ) }
                        
                        // Empty string
                        charIndex += 1
                        lineCharIndex += 1
                        
                    } else {
                        
                        if verbose { print("Line \(lineNumber): Starting string at character \(charIndex)" ) }
                        
                        inString = true
                        stringStartLineIndex = lineIndex
                        stringJustStarted = true
                    
                    }
                    
                } else if c2 != nil && c.asciiValue == 45 && c2!.asciiValue == 45 { // 45: Minus
                
                    if verbose { print("Line \(lineNumber): Starting comment at character \(charIndex)" ) }
                    
                    inComment = true
                    
                } else if c2 != nil && c.asciiValue == 40 && c2!.asciiValue == 42 { // 40: Opening parentheses, 42: Asterisk
                    
                    if verbose { print("Line \(lineNumber): Starting comment block at character \(charIndex)" ) }
                    
                    inCommentBlock = true
                    commentBlockStartLineIndex = lineIndex
                    
                } else if !stopCountingIndentation && c.asciiValue == 9 { // 9: Tab
                    
                    indentationBuffer += String(c)
                    
                } else if !stopCountingIndentation && c.asciiValue != 9 { // 9: Tab
                    
                    if verbose && !indentationBuffer.isEmpty {
                        print("Line \(lineNumber): Indentation ended with \"\(indentationBuffer.replacingOccurrences(of: "\t", with: "\\t"))\" at character \(charIndex - 1)" )
                    }
                    stopCountingIndentation = true
                    
                }
                
                if inString && !stringJustStarted {
                    stringBuffer += String(c)
                    
                } else if inComment {
                    commentBuffer += String(c)
                    
                } else if inCommentBlock {
                    commentBlockBuffer += String(c)
                    
                } else if c.asciiValue != 10 && !commentBlockJustEnded {
                    lineBuffer += String(c)
                    
                }
                
                if isEscaped { isEscaped = false }
                
            }
            
            if stringJustStarted { stringJustStarted = false }
            if commentBlockJustEnded { commentBlockJustEnded = false }
            
            charIndex += 1
            lineCharIndex += 1
            if c.asciiValue == 10 {
                
                if verbose && !lineBuffer.isEmpty {
                    print("Line \(lineNumber): \"\(lineBuffer.replacingOccurrences(of: "\t", with: "\\t"))\"")
                }
                
                lines.append(ScriptLine(
                    document: self,
                    number: lineNumber,
                    code: lineBuffer,
                    indentation: indentationBuffer)
                )
                
                lineBuffer = ""
                lineIndex += 1
                lineNumber += 1
                indentationBuffer = ""
                stopCountingIndentation = false
                lineCharIndex = 0
                
            }
            
        }
        
    }
    
    func initHierarchy() {
        
        if verbose { print("Initializing hierarchy") }
        
        for line in lines {
            
             if let topOfStack = stack.last {
                 
                if line.isHeadingStart && topOfStack.isHeadingStart {
                    
                    if verbose { print("Ending heading \"\(topOfStack.headingName)\"") }
                    removeFromTopOfStack(topOfStack)
                    
                } else if (line.isFunctionEnd(functionName: topOfStack.functionName)) {
                    
                    if verbose { print("Ending function \"\(topOfStack.functionName)\"") }
                    removeFromTopOfStack(topOfStack)
                    
                } else if (line.isScriptEnd()) {
                    
                    if topOfStack.isHeadingStart {
                        if verbose { print("Ending heading \"\(topOfStack.headingName)\"") }
                        removeFromTopOfStack(topOfStack)
                    }
                    
                    if let newTopOfStack = stack.last {
                        if verbose { print("Ending script \"\(newTopOfStack.scriptName)\"") }
                        removeFromTopOfStack(newTopOfStack)
                    }
                    
                }
                
            }
            
            if verbose {
                print("Line \(line.number): \(currentPath()) \(line.code)")
            }
            
            line.depth = stack.count
            
            if stack.count == 0 {
                children.append(line)
            } else if let topOfStack = stack.last {
                line.parent = topOfStack
                topOfStack.children.append(line)
            }
            
            if line.isHeadingStart {
                
                if verbose { print("Starting heading \"\(line.headingName)\"") }
                addToStack(line)
                
            } else if line.isFunctionStart {
                
                if verbose { print("Starting function \"\(line.functionName)\"") }
                addToStack(line)
                
            } else if line.isScriptStart {
                
                if verbose { print("Starting script \"\(line.scriptName)\"") }
                addToStack(line)
                
            }
            
        }
        
    }

}
