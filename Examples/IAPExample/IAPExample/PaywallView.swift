import IAP
import StoreKit
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var iap: IAPManager
    @Environment(\.dismiss) private var dismiss

    private var plans: [Product] {
        iap.products.filter { ProductID.premium.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.yellow)
                Text("Unlock Pro").font(.largeTitle.bold())
                Text("All features, no limits.")
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    ForEach(plans, id: \.id) { product in
                        PurchaseButton(product: product, onCompletion: { outcome in
                            if outcome.isSuccess { dismiss() }
                        }) { product in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.displayName).bold()
                                    if let period = product.periodText {
                                        Text("per \(period)").font(.caption)
                                    }
                                }
                                Spacer()
                                Text(product.displayPrice).bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                RestorePurchasesButton()
                    .font(.footnote)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: iap.isPremium) { isPremium in
                if isPremium { dismiss() }
            }
        }
    }
}
