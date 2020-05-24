//
//  ScriptString.swift
//

import Foundation

class ScriptString {
    
    let document: ScriptDocument
    let lineNumber: Int
    let scriptOffset: Int
    let lineOffset: Int
    let text: String
    
    init(document: ScriptDocument, lineNumber: Int, scriptOffset: Int, lineOffset: Int, text: String) {
        
        self.document = document
        self.lineNumber = lineNumber
        self.scriptOffset = scriptOffset
        self.lineOffset = lineOffset
        self.text = text
        
    }
    
}
