import Foundation

public enum IAPError: LocalizedError, Equatable {
    case productNotFound(String)
    case failedVerification
    case purchasesNotAllowed
    case unknown

    public var errorDescription: String? {
        switch self {
        case .productNotFound(let id):
            return "Product \"\(id)\" is not available."
        case .failedVerification:
            return "The transaction could not be verified."
        case .purchasesNotAllowed:
            return "In-app purchases are not allowed on this device."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
