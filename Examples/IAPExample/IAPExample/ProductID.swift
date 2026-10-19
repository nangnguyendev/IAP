enum ProductID {
    static let proMonthly = "com.nguyennn.iapexample.pro.monthly"
    static let proYearly = "com.nguyennn.iapexample.pro.yearly"
    static let lifetime = "com.nguyennn.iapexample.lifetime"
    static let removeAds = "com.nguyennn.iapexample.removeads"
    static let coins100 = "com.nguyennn.iapexample.coins100"
    static let coins500 = "com.nguyennn.iapexample.coins500"

    static let premium: Set<String> = [proMonthly, proYearly, lifetime]

    static let coinAmounts: [String: Int] = [
        coins100: 100,
        coins500: 500
    ]

    static let all: Set<String> = premium.union([removeAds]).union(coinAmounts.keys)
}
