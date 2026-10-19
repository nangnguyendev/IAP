import IAP
import StoreKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var iap: IAPManager
    @EnvironmentObject private var wallet: CoinWallet
    @State private var showPaywall = false
    @State private var showManageSubscriptions = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                statusSection
                productSection("Subscriptions", products: iap.subscriptions)
                productSection("Non-consumables", products: iap.nonConsumables)
                productSection("Consumables", products: iap.consumables)
                actionsSection
            }
            .navigationTitle("IAP Example")
            .toolbar {
                if iap.isLoadingProducts || iap.isPurchasing {
                    ProgressView()
                }
            }
            .refreshable {
                await iap.loadProducts()
                await iap.refreshEntitlements()
            }
            .overlay {
                if iap.products.isEmpty && !iap.isLoadingProducts {
                    Text("No products. Check the StoreKit configuration in the scheme.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        #if os(iOS)
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        #endif
        .alert("Error", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(iap.lastError?.localizedDescription ?? "")
        }
        .alert(message ?? "", isPresented: messageBinding) {
            Button("OK", role: .cancel) {}
        }
    }

    private var statusSection: some View {
        Section("Status") {
            LabeledContent("Premium", value: iap.isPremium ? "Yes" : "No")
            LabeledContent("Ads removed", value: iap.isPurchased(ProductID.removeAds) ? "Yes" : "No")
            LabeledContent("Coins", value: "\(wallet.balance)")
            ForEach(iap.entitlements, id: \.id) { transaction in
                VStack(alignment: .leading) {
                    Text(transaction.productID).font(.footnote.monospaced())
                    if let expiration = transaction.expirationDate {
                        Text("Expires \(expiration.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func productSection(_ title: String, products: [Product]) -> some View {
        Section(title) {
            ForEach(products, id: \.id) { product in
                ProductRow(product: product) { outcome in
                    handle(outcome, for: product)
                }
            }
        }
    }

    private var actionsSection: some View {
        Section {
            Button("Show paywall") { showPaywall = true }
            Button("Spend 50 coins") {
                message = wallet.spend(50) ? "Spent 50 coins." : "Not enough coins."
            }
            RestorePurchasesButton()
            #if os(iOS)
            Button("Manage subscriptions") { showManageSubscriptions = true }
            #endif
        }
    }

    private func handle(_ outcome: PurchaseOutcome, for product: Product) {
        switch outcome {
        case .success:
            message = "Purchased \(product.displayName)."
        case .pending:
            message = "Purchase of \(product.displayName) is pending approval."
        case .cancelled:
            break
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { iap.lastError != nil },
            set: { if !$0 { iap.lastError = nil } }
        )
    }

    private var messageBinding: Binding<Bool> {
        Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )
    }
}
