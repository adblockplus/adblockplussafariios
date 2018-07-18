/// For iterating enums until Swift 4.2.
/// Source: https://stackoverflow.com/questions/24007461/how-to-enumerate-an-enum-with-string-type
#if swift(>=4.2)
#else
protocol CaseIterable {
    associatedtype AllCases: Collection where AllCases.Element == Self

    static var allCases: AllCases { get }
}

extension CaseIterable where Self: Hashable {
    static var allCases: [Self] {
        return [Self](AnySequence { () -> AnyIterator<Self> in
            var raw = 0
            var first: Self?
            return AnyIterator {
                let current = withUnsafeBytes(of: &raw) { $0.load(as: Self.self) }
                if raw == 0 {
                    first = current
                } else if current == first {
                    return nil
                }
                raw += 1
                return current
            }
        })
    }
}
#endif
