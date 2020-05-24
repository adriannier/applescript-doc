//
//  main.swift
//

import Foundation
import ArgumentParser

struct asdoc: ParsableCommand {
    
    static var configuration = CommandConfiguration(
    abstract: "Generates markdown-formatted documentation from an AppleScript file",
    discussion: """
        Compiles the input file with osacompile if necessary and uses osadecompile to produce a standard format that can be easily parsed. Elements that are considered for documentation:
        
        # Headings
        
        Headings are empty functions whose names are prefixed with 32 underscores
        
        Example:
        on ________________________________Public()
        end ________________________________Public
        
        # Functions
        
        Functions prefixed with an underscore are considered private and are omitted from the documentation.

        # Scripts

        Scripts appear at the end of the documentation after all first level functions have been documented.

        # Comment Blocks

        Each first comment block following a heading, function, or script is included without its surrounding whitespace.
        """)
    
    @Option(name: .customLong("blob"), help: ArgumentHelp("The prefix of the URL necessary to link to individual source code lines online", discussion: "Example: https://github.com/yourname/project/blob/master/name.applescript#L\n", valueName: "url"))
    
    var blobURLPrefix: String?
    
    @Flag(name: .shortAndLong)
    var verbose: Bool
    
    @Argument(help: "An AppleScript file (.scpt or .applescript)")
    var input: String
     
    @Argument(help: "Path to the markdown file that will be created")
    var output: String
    
    func run() throws {

        let start = Date()
        
        // Get information on input file
        let inputFile = NSString(string: input).expandingTildeInPath
        let inputURL = URL(fileURLWithPath: inputFile)
        let inputDirectoryURL = inputURL.deletingLastPathComponent()
        let inputDirectory = inputDirectoryURL.path
        let inputName = inputURL.lastPathComponent
        
        // Get information on output file
        let outputFile = NSString(string: output).expandingTildeInPath
        let outputURL = URL(fileURLWithPath: outputFile)
        let outputDirectoryURL = outputURL.deletingLastPathComponent()
        let outputDirectory = outputDirectoryURL.path
      
        // Check input and output file
        if !isReadable(at: inputDirectory) {
            throw FilesystemError("Could not read from input directory at \(inputDirectory)")
            
        } else if !fileExists(at: inputFile) {
            throw FilesystemError("Could not find input file at \(inputFile)")
            
        } else if !isReadable(at: inputFile) {
            throw FilesystemError("Input file is not readable at \(inputFile)")
            
        } else if !directoryExists(at: outputDirectory) {
            throw FilesystemError("Could not find output directory at \(outputDirectory)")
        
        } else if !isWritable(at: outputDirectory) {
            throw FilesystemError("Output directory is not writable at \(outputDirectory)")
        
        } else if fileExists(at: inputFile) && !isWritable(at: inputFile) {
            throw FilesystemError("Output file exists and is not writable at \(outputDirectory)")
            
        }
            
        if verbose { print("Generating documentation from \(inputFile)") }
        
        let source = try appleScriptSource(file: inputFile, verbose: verbose)
        
        let script = ScriptDocument(
            withSource: source,
            name: inputName,
            blobURLPrefix: blobURLPrefix,
            verbose: verbose
        )
            
        try script.writeDocumentation(to: outputFile)
            
        if verbose {
            print("Wrote documentation to \(outputFile)")
            if verbose { printDuration(msg: "Total run time was", start: start) }
        }

    }
    
    

}

asdoc.main()
