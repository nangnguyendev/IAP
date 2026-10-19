import StoreKit

public enum PurchaseOutcome: Sendable {
    case success(Transaction)
    case pending
    case cancelled

    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}
