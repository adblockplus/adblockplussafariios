//
//  IKILogger.swift
//
//  version 3.0.0
//
//  The MIT License (MIT)
//  Copyright (c) 2017 ikiApps LLC.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

/**
 This library provides logging functions for debugging Swift.

 IKILogger lets you tag debugging output with colored symbols and keeps the logging
 from printing to stdout so that it is not seen by end users.

 Dates are added to logging commands to give them context in time. Additionally,
 logging output can be suppressed by a date cutoff.

 Colored debugging logging enhances logs by adding an extra dimension of
 debugging data that can be quickly discerned without reading.

 In this library, the meaning of CRITICAL is assigned to the color red and the
 double exclamation symbol (!!). This color value will always be logged and is,
 therefore, useful for printing NSError occurrences.

 Usage Examples:

 dLog("data \(data)", date: "2016-Jul-28");

 dLogYellow("", date: "2016-Jul-28")

 dLogRed("error \(error)", date: "2016-Jul-28");
 */

/// Flag to enable logging output through IKILogger.
public var ikiLoggerEnabled = true

/// Cut off output that has a logging date before this date. The format of this string is "yyyy-MMM-dd".
public var ikiLoggerSuppressBeforeDate = "2000-Jan-01"

/// A prefix that can be used for filtering output.
public var ikiLoggerPrefix = "ikiApps"

/// Determine whether or not to use color output.
public var ikiLoggerUseColor = false

struct LogSymbol
{
    static let critical = "‼️" // Messages using this color will always be logged.
    static let important = "✴️" // Eight point star.
    static let highlighted = "💛"
    static let reviewed = "✅"
    static let valuable = "💙"
    static let toBeReviewed = "💜"
    static let notImportant = "❔"
    static let none = "⬜️"
}

public func dLog(_ message: String?, date: String? = nil, filename: String = #file, function: String = #function, line: Int = #line)
{
    logMessageWithColor(color: LogSymbol.none, message: message, date: date, filename: filename, function: function, line: line)
}

public func dLogRed(_ message: String?, date: String? = nil, filename: String = #file, function: String = #function, line: Int = #line)
{
    logMessageWithColor(color: LogSymbol.critical, message: message, date: date, filename: filename, function: function, line: line)
}

public func dLogOrange(_ message: String?, date: String? = nil, filename: String = #file, function: String = #function, line: Int = #line)
{
    logMessageWithColor(color: LogSymbol.important, message: message, date: date, filename: filename, function: function, line: line)
}

public func dLogYellow(_ message: String?, date: String? = nil, filename: String = #file, function: String = #function, line: Int = #line)
{
    logMessageWithColor(color: LogSymbol.highlighted, message: message, date: date, filename: filename, function: function, line: line)
}

public func dLogGreen(_ message: String?, date: String? = nil, filename: String = #file, function: String = #function, line: Int = #line)
{
    logMessageWithColor(color: LogSymbol.reviewed, message: message, date: date, filename: filename, function: function, line: line)
}

public func dLogBlue(_ message: String?, date: String? = nil, filename: String = #file, function: String = #function, line: Int = #line)
{
    logMessageWithColor(color: LogSymbol.valuable, message: message, date: date, filename: filename, function: function, line: line)
}

public func dLogPurple(_ message: String?, date: String? = nil, filename: String = #file, function: String = #function, line: Int = #line)
{
    logMessageWithColor(color: LogSymbol.toBeReviewed, message: message, date: date, filename: filename, function: function, line: line)
}

public func dLogGray(_ message: String?, date: String? = nil, filename: String = #file, function: String = #function, line: Int = #line)
{
    logMessageWithColor(color: LogSymbol.notImportant, message: message, date: date, filename: filename, function: function, line: line)
}

#if VERBOSE_DEBUG
    // Verbose debugging has not been implemented yet.
#else
    public func vLog(_ message: String, date: String? = nil) {}
    public func vLogRed(_ message: String, date: String? = nil) {}
    public func vLogOrange(_ message: String, date: String? = nil) {}
    public func vLogYellow(_ message: String, date: String? = nil) {}
    public func vLogGreen(_ message: String, date: String? = nil) {}
    public func vLogBlue(_ message: String, date: String? = nil) {}
    public func vLogPurple(_ message: String, date: String? = nil) {}
    public func vLogGray(_ message: String, date: String? = nil) {}
#endif

// ------------------------------------------------------------
// MARK: - Private -
// ------------------------------------------------------------

/// Print a logging message using color output.
private func logMessageWithColor(color: String,
                                 message: String?,
                                 date: String?,
                                 filename: String,
                                 function: String,
                                 line: Int)
{
    guard let dateString = date, ikiLoggerEnabled else
    {
        return
    }

    if messageShouldBeLoggedBasedOnDate(dateString: dateString,
                                        colorString: color)
    {
        if let uwMessage = message as String?
        {
            logMultilineMessage(color: color,
                                filename: filename,
                                line: line,
                                function: function,
                                message: uwMessage)
        }
    }
}

/// Decide if a date comparison should be ignored based on the logging color.
private func dateComparisonShouldBeIgnored(colorString: String) -> Bool
{
    var ignoreDateComparison = false

    // Ignore date comparisons if the color level is CRITICAL.
    if colorString == LogSymbol.critical
    {
        ignoreDateComparison = true
    }

    return ignoreDateComparison
}

/// Log the message if the creation date for the message is after the suppression date
/// and the color is not set for forced logging.
private func messageShouldBeLoggedBasedOnDate(dateString: String,
                                              colorString: String) -> Bool
{
    if dateComparisonShouldBeIgnored(colorString: colorString) { return true }

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MMM-dd"
    let newDate = formatter.date(from: dateString)
    var printMessage = false
    let beforeDate = formatter.date(from: ikiLoggerSuppressBeforeDate)

    if let uwNewDate = newDate, let uwBeforeDate = beforeDate {
        if uwNewDate.compare(uwBeforeDate) == ComparisonResult.orderedDescending {
            printMessage = true
        }
    }

    return printMessage
}

/// Log a message that may contain multiple lines.
/// Use Crashlytics if it is defined.
private func logMultilineMessage(color: String,
                                 filename: String,
                                 line: Int,
                                 function: String,
                                 message: String)
{
    let splitMessage = message.components(separatedBy: "\n")

    for textLine in splitMessage
    {
        #if DEBUG
            if ikiLogger_useColor {
                NSLog("\(ikiLogger_prefix) \(color) -[\((filename as NSString).lastPathComponent):\(line)] \(function) - \(textLine)")
            } else {
                NSLog("\(ikiLogger_prefix) -[\((filename as NSString).lastPathComponent):\(line)] \(function) - \(textLine)")
            }
        #else
            // No message will be printed unless DEBUG is defined in the building settings under Other Swift Flags.
        #endif
    }
}
