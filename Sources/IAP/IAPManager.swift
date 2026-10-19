import Foundation
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class IAPManager: ObservableObject {
    @Published public private(set) var products: [Product] = []
    @Published public private(set) var purchasedProductIDs: Set<String> = []
    @Published public private(set) var entitlements: [Transaction] = []
    @Published public private(set) var isLoadingProducts = false
    @Published public private(set) var isPurchasing = false
    @Published public var lastError: Error?

    public let configuration: IAPConfiguration

    public var transactionHandler: (@MainActor (Transaction) async -> Void)?

    private var updatesTask: Task<Void, Never>?

    public init(configuration: IAPConfiguration) {
        self.configuration = configuration
    }

    public convenience init(productIDs: Set<String>) {
        self.init(configuration: IAPConfiguration(productIDs: productIDs))
    }

    deinit {
        updatesTask?.cancel()
    }

    public func start() async {
        listenForTransactions()
        await processUnfinishedTransactions()
        await loadProducts()
        await refreshEntitlements()
    }

    public func stop() {
        updatesTask?.cancel()
        updatesTask = nil
    }

    public var isPremium: Bool {
        guard let premiumIDs = configuration.premiumProductIDs else { return !purchasedProductIDs.isEmpty }
        return !purchasedProductIDs.isDisjoint(with: premiumIDs)
    }

    public var subscriptions: [Product] { products.filter { $0.type == .autoRenewable } }
    public var nonConsumables: [Product] { products.filter { $0.type == .nonConsumable } }
    public var consumables: [Product] { products.filter { $0.type == .consumable } }

    public func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    public func isPurchased(_ productID: String) -> Bool {
        purchasedProductIDs.contains(productID)
    }

    public func expirationDate(for productID: String) -> Date? {
        entitlements.first { $0.productID == productID }?.expirationDate
    }

    public func loadProducts() async {
        guard !configuration.productIDs.isEmpty else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let fetched = try await Product.products(for: configuration.productIDs)
            products = fetched.sorted { $0.price < $1.price }
            lastError = nil
        } catch {
            lastError = error
        }
    }

    @discardableResult
    public func purchase(_ product: Product, appAccountToken: UUID? = nil) async throws -> PurchaseOutcome {
        guard AppStore.canMakePayments else { throw record(IAPError.purchasesNotAllowed) }

        isPurchasing = true
        defer { isPurchasing = false }

        var options: Set<Product.PurchaseOption> = []
        if let appAccountToken {
            options.insert(.appAccountToken(appAccountToken))
        }

        do {
            let result = try await product.purchase(options: options)
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handle(transaction)
                lastError = nil
                return .success(transaction)
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                throw IAPError.unknown
            }
        } catch {
            throw record(error)
        }
    }

    @discardableResult
    public func purchase(productID: String, appAccountToken: UUID? = nil) async throws -> PurchaseOutcome {
        if products.isEmpty { await loadProducts() }
        guard let product = product(for: productID) else {
            throw record(IAPError.productNotFound(productID))
        }
        return try await purchase(product, appAccountToken: appAccountToken)
    }

    public func restorePurchases() async throws {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            lastError = nil
        } catch {
            throw record(error)
        }
    }

    public func refreshEntitlements() async {
        var owned: [Transaction] = []
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result),
                  transaction.revocationDate == nil else { continue }
            owned.append(transaction)
        }
        entitlements = owned
        purchasedProductIDs = Set(owned.map(\.productID))
    }

    #if os(iOS)
    public func showManageSubscriptions(in scene: UIWindowScene) async throws {
        try await AppStore.showManageSubscriptions(in: scene)
    }
    #endif

    private func listenForTransactions() {
        guard updatesTask == nil else { return }
        updatesTask = Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard case .verified(let transaction) = result else { continue }
                await self.handle(transaction)
            }
        }
    }

    private func processUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            guard case .verified(let transaction) = result else { continue }
            await handle(transaction)
        }
    }

    private func handle(_ transaction: Transaction) async {
        await transactionHandler?(transaction)
        if configuration.autoFinishTransactions {
            await transaction.finish()
        }
        await refreshEntitlements()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw IAPError.failedVerification
        }
    }

    @discardableResult
    private func record(_ error: Error) -> Error {
        lastError = error
        return error
    }
}
