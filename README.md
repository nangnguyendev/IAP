# IAP

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![Platforms](https://img.shields.io/badge/platforms-iOS%2015%20%7C%20macOS%2012%20%7C%20tvOS%2015%20%7C%20watchOS%208-blue.svg)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

A lightweight Swift Package for adding In-App Purchases (StoreKit 2) to iOS apps.

- Load products, purchase, restore, and track entitlements
- Automatically listens to `Transaction.updates` (renewals, Ask to Buy, refunds…)
- Transaction verification (JWS) via StoreKit 2
- Ready-to-use `isPremium` flag for paywalls
- SwiftUI helpers: `PurchaseButton`, `RestorePurchasesButton`
- Supports iOS 15+, macOS 12+, tvOS 15+, watchOS 8+

## Installation

**Xcode:** File ▸ Add Package Dependencies… ▸ paste `https://github.com/nangnguyendev/IAP.git` ▸ Dependency Rule: *Up to Next Major Version* `1.0.0` ▸ add the `IAP` product.

**Package.swift:**

```swift
dependencies: [
    .package(url: "https://github.com/nangnguyendev/IAP.git", from: "1.0.0")
],
targets: [
    .target(name: "MyApp", dependencies: ["IAP"])
]
```

## Usage

### 1. Start at launch

```swift
import SwiftUI
import IAP

@main
struct MyApp: App {
    @StateObject private var iap = IAPManager(configuration: .init(
        productIDs: ["com.myapp.pro.monthly", "com.myapp.pro.yearly", "com.myapp.lifetime"]
    ))

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(iap)
                .task { await iap.start() }
        }
    }
}
```

### 2. Check premium access

```swift
struct ContentView: View {
    @EnvironmentObject var iap: IAPManager

    var body: some View {
        if iap.isPremium {
            PremiumContent()
        } else {
            PaywallView()
        }
    }
}
```

### 3. Paywall

```swift
struct PaywallView: View {
    @EnvironmentObject var iap: IAPManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 12) {
            ForEach(iap.products, id: \.id) { product in
                PurchaseButton(product: product) { outcome in
                    if outcome.isSuccess { dismiss() }
                }
                if let perMonth = product.monthlyPriceText, product.periodText != nil {
                    Text("\(perMonth) / month").font(.caption)
                }
            }
            RestorePurchasesButton()
        }
        .overlay { if iap.isLoadingProducts { ProgressView() } }
    }
}
```

### 4. Purchase from code (UIKit or custom logic)

```swift
do {
    switch try await iap.purchase(productID: "com.myapp.lifetime") {
    case .success(let transaction): print("Purchased", transaction.productID)
    case .pending:                  print("Waiting for approval (Ask to Buy)")
    case .cancelled:                break
    }
} catch {
    print(error.localizedDescription)
}
```

### 5. Consumables / backend sync

Transactions are finished automatically by default. To deliver consumables (e.g. coins) or notify your server before a transaction is finished:

```swift
iap.transactionHandler = { transaction in
    if transaction.productID == "com.myapp.coins100" {
        await CoinStore.shared.add(100)
    }
}
```

The handler runs on the main actor. If you need to finish transactions yourself (e.g. after your server confirms delivery), set `autoFinishTransactions: false` in the configuration and call `await transaction.finish()` inside `transactionHandler` once the content has been delivered.

### 6. Choose which products count as "premium"

```swift
IAPConfiguration(
    productIDs: ["pro.monthly", "pro.yearly", "remove_ads"],
    premiumProductIDs: ["pro.monthly", "pro.yearly"]
)
```

Here owning `remove_ads` does not make `isPremium` true. When `premiumProductIDs` is `nil`, any non-consumable or active subscription counts as premium.

## API overview

| Member | Description |
|---|---|
| `start()` | Starts listening for transactions, processes unfinished ones, loads products and entitlements |
| `products`, `subscriptions`, `nonConsumables`, `consumables` | Available products, sorted by price |
| `purchase(_:)` / `purchase(productID:)` | Buys a product and returns a `PurchaseOutcome` |
| `restorePurchases()` | Calls `AppStore.sync()` — use only from a Restore button |
| `isPremium`, `isPurchased(_:)`, `purchasedProductIDs` | Ownership state |
| `expirationDate(for:)` | Subscription expiration date |
| `showManageSubscriptions(in:)` | (iOS) Presents the Manage Subscriptions sheet |
| `Product.periodText`, `.monthlyPriceText`, `.isEligibleForIntroOffer` | Display helpers |

## Example app

`Examples/IAPExample` is a SwiftUI app (iOS 16+) that uses this package via a local path and ships with a `Products.storekit` file, so you can test without App Store Connect:

| Product ID | Type | Price |
|---|---|---|
| `com.nguyennn.iapexample.pro.monthly` | Auto-renewable | $4.99 / month |
| `com.nguyennn.iapexample.pro.yearly` | Auto-renewable (1-week free trial) | $29.99 / year |
| `com.nguyennn.iapexample.lifetime` | Non-consumable | $29.99 |
| `com.nguyennn.iapexample.removeads` | Non-consumable | $1.99 |
| `com.nguyennn.iapexample.coins100` / `coins500` | Consumable | $0.99 / $3.99 |

To run it:

1. Open `Examples/IAPExample/IAPExample.xcodeproj`.
2. Select the **IAPExample** scheme and a simulator, then press Run. The scheme already uses `Products.storekit`. If the product list is empty, go to *Edit Scheme ▸ Run ▸ Options ▸ StoreKit Configuration* and select `Products.storekit` again.
3. Try the flows: buy a subscription or lifetime (Premium switches to Yes), buy coins (balance increases via `transactionHandler`), Restore, Manage subscriptions, and the paywall.
4. Use *Debug ▸ StoreKit ▸ Manage Transactions* to refund, speed up renewals, or enable *Ask to Buy* to test the pending state.

## Testing in your own app

1. Xcode ▸ File ▸ New ▸ File… ▸ **StoreKit Configuration File**, and add the same product IDs as in App Store Connect.
2. Edit Scheme ▸ Run ▸ Options ▸ **StoreKit Configuration** ▸ select the new file.
3. Run on a simulator — purchases, refunds and renewals can be simulated via *Debug ▸ StoreKit ▸ Manage Transactions*.

## Releasing a new version

This package follows [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`.

1. Record the changes in `CHANGELOG.md`.
2. Commit, tag, and push:

```bash
git tag 1.1.0
git push origin main --tags
```

Apps using *Up to Next Major Version* pick up the new release via File ▸ Packages ▸ Update to Latest Package Versions.

## License

Released under the MIT License. See [LICENSE](LICENSE).
