#if canImport(SwiftUI)
import StoreKit
import SwiftUI

public struct PurchaseButton<Label: View>: View {
    @EnvironmentObject private var iap: IAPManager

    private let product: Product
    private let onCompletion: (PurchaseOutcome) -> Void
    private let label: (Product) -> Label

    public init(
        product: Product,
        onCompletion: @escaping (PurchaseOutcome) -> Void = { _ in },
        @ViewBuilder label: @escaping (Product) -> Label
    ) {
        self.product = product
        self.onCompletion = onCompletion
        self.label = label
    }

    public var body: some View {
        Button {
            Task {
                if let outcome = try? await iap.purchase(product) {
                    onCompletion(outcome)
                }
            }
        } label: {
            label(product)
        }
        .disabled(iap.isPurchasing || iap.isPurchased(product.id))
    }
}

public extension PurchaseButton where Label == Text {
    init(product: Product, onCompletion: @escaping (PurchaseOutcome) -> Void = { _ in }) {
        self.init(product: product, onCompletion: onCompletion) { product in
            Text("\(product.displayName) – \(product.displayPrice)")
        }
    }
}

public struct RestorePurchasesButton: View {
    @EnvironmentObject private var iap: IAPManager
    private let title: LocalizedStringKey

    public init(_ title: LocalizedStringKey = "Restore Purchases") {
        self.title = title
    }

    public var body: some View {
        Button(title) {
            Task { try? await iap.restorePurchases() }
        }
        .disabled(iap.isPurchasing)
    }
}
#endif
