class ABPDebug
{
    class func printFilterLists(_ lists: [FilterList])
    {
        dLog("🐰", date: "2017-Dec-27")
        
        debugPrint("📜 Filter Lists:")
        var cnt = 1
        for list in lists {
            debugPrint("\(cnt). \(list)\n")
            cnt += 1
        }
    }
}
