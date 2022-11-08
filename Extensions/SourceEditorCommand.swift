//
//  SourceEditorCommand.swift
//  Extensions
//
//  Created by Roman Baev on 04.03.2022.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {

  func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
    defer { completionHandler(nil) }
    let selections = invocation.buffer.selections
    guard let firstSelection = selections.firstObject as? XCSourceTextRange,
          let lastSelection = selections.lastObject as? XCSourceTextRange else {
            return
          }
    let startLine = firstSelection.start.line
    let endLine = max(lastSelection.end.line, startLine + 1)
    let selectionRange = startLine..<endLine
    let lines = invocation.buffer.lines.compactMap { $0 as? String }
    let selectedLines = selectionRange.map { ($0, lines[$0]) }

    for (index, line) in selectedLines {
      guard line.contains(regex: #"(\ *)(.+\()(.+)(\).*)"#) else {
        continue
      }
      let formattedLines = formatFunctions(at: line).reversed()
      invocation.buffer.lines.removeObject(at: index)
      for formattedLine in formattedLines {
        invocation.buffer.lines.insert(formattedLine, at: index)
      }
      break
    }
    invocation.buffer.selections.removeAllObjects()
  }
}

func formatFunctions(at line: String) -> [String] {
  let identationSpaces = getIdentationSpaces(at: line)
  var formattedLines: [String] = []
  let pattern = #"(\ *)(.+\()(.+)(\).*)"#
  let regex = try? NSRegularExpression(pattern: pattern)
  let range = NSRange(location: 0, length: line.utf16.count)
  let matches = regex?.matches(in: line, range: range)

  for match in matches ?? [] {
    let firstLine = line.substring(with: match.range(at: 2))
    let middleLines = line.substring(with: match.range(at: 3))
      .replacingOccurrences(of: ", ", with: ",  ")
      .components(separatedBy: "  ")
      .filter { !$0.isEmpty }
      .map { "  " + $0 }
    let lastLine = line.substring(with: match.range(at: 4))
    formattedLines += [firstLine] + middleLines + [lastLine]
  }
  return formattedLines
    .map { identationSpaces + $0 }
}

func getIdentationSpaces(at line: String) -> String {
  let pattern = #"(^\s+)"#
  let regex = try? NSRegularExpression(pattern: pattern)
  let range = NSRange(location: 0, length: line.utf16.count)
  let match = regex?.matches(in: line, range: range).first

  guard let match else { return "" }
  return line.substring(with: match.range(at: 1))
}

extension String {
  func contains(regex: String) -> Bool {
    let regex = try? NSRegularExpression(pattern: regex)
    let range = NSRange(location: 0, length: utf16.count)
    let matches = regex?.matches(in: self, range: range)
    return matches?.isEmpty == false
  }

  private func index(from: Int) -> Index {
    return self.index(startIndex, offsetBy: from)
  }

  func substring(with range: NSRange) -> String {
    let startIndex = index(from: range.lowerBound)
    let endIndex = index(from: range.upperBound)
    return String(self[startIndex..<endIndex])
  }
}
