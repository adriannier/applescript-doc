//
//  Comment.swift
//

import Foundation

class ScriptComment {
    
    let document: ScriptDocument
    let lineNumber: Int
    let scriptOffset: Int
    let lineOffset: Int
    let text: String
    let isBlock: Bool
    
    init(document: ScriptDocument, lineNumber: Int, scriptOffset: Int, lineOffset: Int, text: String, isBlock: Bool) {
        
        self.document = document
        self.lineNumber = lineNumber
        self.scriptOffset = scriptOffset
        self.lineOffset = lineOffset
        self.text = text
        self.isBlock = isBlock
        
       
        
    }
    
    func content() -> String {
        
        var content : String
        
        if (isBlock) {
            
            let indentedContent = text.dropFirst(2).dropLast(2).trimmingCharacters(in: .whitespacesAndNewlines)
            let lines = indentedContent.components(separatedBy: "\n")
            
            var newLines: [String] = []
            let expectedIndentation = document.lines[lineNumber - 1].indentation
            
            for line in lines {
                
                if line.starts(with: "\(expectedIndentation)\t") {
                    newLines.append(line.deletingPrefix("\(expectedIndentation)\t"))
                } else if line.starts(with: expectedIndentation) {
                    newLines.append(line.deletingPrefix(expectedIndentation))
                } else {
                    newLines.append(line)
                }
                
            }
            
            content = newLines.joined(separator: "\n")
            
            
        } else {
            content = text.dropFirst(2).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return content
        
    }
    
}
