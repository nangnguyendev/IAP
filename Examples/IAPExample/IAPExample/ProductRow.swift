import IAP
import StoreKit
import SwiftUI

struct ProductRow: View {
    @EnvironmentObject private var iap: IAPManager
    let product: Product
    let onCompletion: (PurchaseOutcome) -> Void
    @State private var eligibleForTrial = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName).font(.headline)
                Text(product.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let period = product.periodText {
                    Text("Every \(period)").font(.caption)
                }
                if let monthly = product.monthlyPriceText, product.subscription?.subscriptionPeriod.unit == .year {
                    Text("\(monthly) / month").font(.caption).foregroundStyle(.green)
                }
                if eligibleForTrial, let offer = product.subscription?.introductoryOffer {
                    Text("Free trial: \(offer.period.localizedText)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            if iap.isPurchased(product.id) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            } else {
                PurchaseButton(product: product, onCompletion: onCompletion) { product in
                    Text(product.displayPrice)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .task(id: iap.purchasedProductIDs) {
            eligibleForTrial = await product.isEligibleForIntroOffer
        }
    }
}
