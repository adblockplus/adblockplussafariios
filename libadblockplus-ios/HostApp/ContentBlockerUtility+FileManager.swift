/*
 * This file is part of Adblock Plus <https://adblockplus.org/>,
 * Copyright (C) 2006-present eyeo GmbH
 *
 * Adblock Plus is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * Adblock Plus is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Adblock Plus.  If not, see <http://www.gnu.org/licenses/>.
 */

extension ContentBlockerUtility {
    public func blocklistData(blocklist fileURL: BlockListFileURL) throws -> BlockListData {
        let fmgr = FileManager.default
        if let data = fmgr.contents(atPath: fileURL.path) {
            return data
        } else {
            throw ABPFilterListError.notFound
        }
    }

    public func rulesDir(blocklist fileURL: BlockListFileURL) -> BlockListDirectoryURL {
        var mutable = fileURL
        mutable.deleteLastPathComponent()
        return mutable
    }

    public func makeNewBlocklistFileURL(name: BlockListFilename,
                                        at directory: BlockListDirectoryURL) -> BlockListFileURL {
        return directory.appendingPathComponent(name)
    }

    public func startBlockListFile(blocklist: BlockListFileURL) throws {
        do {
            try Constants.blocklistArrayStart
                .write(to: blocklist,
                       atomically: true,
                       encoding: Constants.blocklistEncoding)
        } catch let error {
            throw error
        }
    }

    public func endBlockListFile(blocklist: BlockListFileURL) {
        if let outStream = OutputStream(url: blocklist,
                                        append: true) {
            outStream.open()
            outStream.write(Constants.blocklistArrayEnd,
                            maxLength: 1)
            outStream.close()
        }
    }

    public func addRuleSeparator(blocklist: BlockListFileURL) {
        if let outStream = OutputStream(url: blocklist,
                                        append: true) {

            outStream.open()
            outStream.write(Constants.blocklistRuleSeparator,
                            maxLength: 1)
            outStream.close()
        }
    }

    public func writeToEndOfFile(blocklist: BlockListFileURL,
                                 with data: Data) {
        if let fileHandle = try? FileHandle(forWritingTo: blocklist) {
             defer {
                 fileHandle.closeFile()
             }
             fileHandle.seekToEndOfFile()
             fileHandle.write(data)
         }
    }
}
