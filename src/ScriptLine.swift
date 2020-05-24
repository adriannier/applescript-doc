//
//  Line.swift
//

import Foundation

class ScriptLine {
    
    let document: ScriptDocument
    let number: Int
    
    let code: String
    let emptyCode: Bool
    
    var depth = 0
    
    let indentation: String
    
    var htmlHeaderId = ""
    
    var isHeadingStart = false
    var isFunctionStart = false
    var isScriptStart = false
        
    var headingName = ""
    
    var functionName = ""
    var functionParameters : String?
    var functionNameWithParameters = ""
    var isPrivateFunction = false
    
    var scriptName = ""
    
    var headingContainsOnlyPrivateFunctions: Bool?
    
    var parent : ScriptLine?
    var children : [ScriptLine] = []
    
    init(document: ScriptDocument, number: Int, code: String, indentation: String) {
        
        self.document = document
        self.number = number
        
        self.code = code
        self.emptyCode = code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        self.indentation = indentation
        
        self.isHeadingStart = code.starts(with: "\(indentation)on \(document.headingMarker)")
        if (!self.isHeadingStart) {
            self.isFunctionStart = code.starts(with: "\(indentation)on ") &&
                                    code != "\(indentation)on error" &&
                                    !code.starts(with: "\(indentation)on error ")
        } else {
            self.isFunctionStart = false
        }
        
        if !self.isHeadingStart && !self.isFunctionStart {
            self.isScriptStart = code.starts(with: "\(indentation)script ")
        } else {
            self.isScriptStart = false
        }
        
        if self.isHeadingStart {
            
            if let headingName = code.slice(from:"\(indentation)on \(document.headingMarker)", to:"(") {
                self.headingName = headingName.replacingOccurrences(of: "_", with: " ")
                self.htmlHeaderId = convertToHTMLHeaderId(headingName)
            } else {
                self.headingName = ""
            }
            
        }
        
        if self.isFunctionStart {
            
            if let functionName = code.slice(from:"\(indentation)on ", to:"(") {
                self.functionName = functionName
                if let functionParameters = code.slice(from:"(", to: ")") {
                    self.functionParameters = functionParameters
                    self.functionNameWithParameters = "\(functionName)(\(functionParameters))"
                }
            } else {
                self.functionName = code.deletingPrefix("\(indentation)on ").trimmingCharacters(in: .whitespaces)
                self.functionNameWithParameters = functionName
            }
            
            if self.functionName.starts(with: "_") {
                self.isPrivateFunction = true
            }
            
            self.htmlHeaderId = convertToHTMLHeaderId(functionNameWithParameters)
        
        }
        
        if self.isScriptStart {
            self.scriptName = code.deletingPrefix("\(indentation)script ").trimmingCharacters(in: .whitespaces)
            self.htmlHeaderId = convertToHTMLHeaderId("Script: \(scriptName)")
        }
        
        

    }
    
    func isHeadingEnd(headingName: String) -> Bool {
        
        return code == "\(indentation)end \(document.headingMarker)\(headingName)" || code == "\(indentation)end \(document.headingMarker)\(headingName) "
        
    }
    
    func isFunctionEnd(functionName: String) -> Bool {
        
        return code == "\(indentation)end \(functionName)" || code == "\(indentation)end \(functionName) "
        
    }
    
    func isScriptEnd() -> Bool {
           
       return code == "\(indentation)end script" || code == "\(indentation)end script "
           
    }
    
    func isHeadingWithOnlyPrivateFunctions() -> Bool {
     
        if headingContainsOnlyPrivateFunctions == nil {
            
            // Check if heading contains only private function
            if isHeadingStart {
                
                // Check if this heading contains only private functions
                var privateFunctionCount = 0
                var functionCount = 0
                var otherCount = 0
                 
                for child in children {
                    
                    if child.isFunctionStart {
                        functionCount += 1
                        if child.isPrivateFunction {
                            privateFunctionCount += 1
                        }
                    } else if child.isScriptStart || child.isHeadingStart {
                        otherCount += 1
                    }
                }
                
                if otherCount == 0 && functionCount == privateFunctionCount {
                    headingContainsOnlyPrivateFunctions = true
                } else {
                    headingContainsOnlyPrivateFunctions = false
                }
                
            }
            
        }
        
        return headingContainsOnlyPrivateFunctions!
        
    }
    
    func isBlank() -> Bool {
        
          return emptyCode && document.comments[number] == nil
        
    }
    
    
    func name() -> String {
        
        if isHeadingStart {
            return headingName
        } else if isFunctionStart {
            return functionName
        } else if isScriptStart {
            return scriptName
        } else {
            return code
        }

    }
    
    func generateTableOfContents(depthOffset: Int) {
        
        // Generate the indentation string
        let indentation = String(repeating: " ", count: (depth + depthOffset) * 2)
        
        if isHeadingStart {
            
            // Heading
            
            if !isHeadingWithOnlyPrivateFunctions() {
                
                // Add heading to table of contents
                document.add("\(indentation)- [\(headingName)](#\(htmlHeaderId))")
                
                // Make this heading's children generate their table of contents as well
                for child in children {
                    child.generateTableOfContents(depthOffset: depthOffset)
                }
                
            }

        } else if isFunctionStart && !isPrivateFunction {
            
            // Add function to table of contents
            document.add("\(indentation)- [`\(functionNameWithParameters)`](#\(htmlHeaderId))")
            
        } else if isScriptStart {
            
            // Add script to table of contents
            document.add("\(indentation)- [Script:`\(scriptName)`](#\(htmlHeaderId))")
            
            // Make this script's children generate their table of contents as well
            for child in children {
                child.generateTableOfContents(depthOffset: depthOffset)
            }
            
        }
        
    }
    
    func addChildComment() {
        
        let startChildIndex: Int
        
        if (isHeadingStart) {
            startChildIndex = 1
        } else {
            startChildIndex = 0
        }
        
        for index in startChildIndex..<children.count {
         
            let child = children[index]
             
            if !child.isBlank() {
                
                if let comment = document.comments[child.number] {
                    if isFunctionStart {
                        document.addBlank()
                    }
                    document.add("\(comment.content())")
                    document.addBlank()
                }
                break
                
            }
            
        }
        
    }

    func generateDocumentation(depthOffset: Int) {
        
        let hashes = String(repeating: "#", count: depth + depthOffset)
        
        if isHeadingStart {
        
            if !isHeadingWithOnlyPrivateFunctions() {
                
                document.addBlankIfNecessary()
                document.add("\(hashes) \(headingName)")
                document.addBlank()
                
                addChildComment()
                
                for child in children {
                    child.generateDocumentation(depthOffset: depthOffset)
                }
                
            }
            
        } else if isFunctionStart && !isPrivateFunction {
           
            if let blobURLPrefix = document.blobURLPrefix {
                document.add("\(hashes) [\(functionNameWithParameters)](\(blobURLPrefix)\(number))")
            } else {
                document.add("\(hashes) `\(functionNameWithParameters)`")
            }
            
            addChildComment()
            
        } else if isScriptStart {
           
            document.addBlankIfNecessary()
            
            if let blobURLPrefix = document.blobURLPrefix {
                document.add("\(hashes) [Script: \(scriptName)](\(blobURLPrefix)\(number))")
            } else {
                document.add("\(hashes) Script: \(scriptName)")
            }
            document.addBlank()
            
            addChildComment()
            
            for child in children {
                child.generateDocumentation(depthOffset: depthOffset)
            }

            
        }
        
    }
    
}
