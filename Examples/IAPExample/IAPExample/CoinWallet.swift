import Foundation

@MainActor
final class CoinWallet: ObservableObject {
    private static let key = "coinBalance"

    @Published private(set) var balance: Int {
        didSet { UserDefaults.standard.set(balance, forKey: Self.key) }
    }

    init() {
        balance = UserDefaults.standard.integer(forKey: Self.key)
    }

    func add(_ amount: Int) {
        balance += amount
    }

    @discardableResult
    func spend(_ amount: Int) -> Bool {
        guard balance >= amount else { return false }
        balance -= amount
        return true
    }
}
