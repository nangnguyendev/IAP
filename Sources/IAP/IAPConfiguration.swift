import Foundation

public struct IAPConfiguration: Sendable, Equatable {
    public var productIDs: Set<String>

    public var premiumProductIDs: Set<String>?

    public var autoFinishTransactions: Bool

    public init(
        productIDs: Set<String>,
        premiumProductIDs: Set<String>? = nil,
        autoFinishTransactions: Bool = true
    ) {
        self.productIDs = productIDs
        self.premiumProductIDs = premiumProductIDs
        self.autoFinishTransactions = autoFinishTransactions
    }
}
