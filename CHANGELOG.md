# Changelog

## [1.0.1] - 2026-10-19

### Added
- MIT license.

### Changed
- README and CHANGELOG translated to English.

## [1.0.0] - 2026-10-19

### Added
- `IAPManager` built on StoreKit 2: load products, purchase, restore, and track entitlements.
- Automatically listens to `Transaction.updates` and processes `Transaction.unfinished` at launch.
- `IAPConfiguration` with `premiumProductIDs` and `autoFinishTransactions`.
- `transactionHandler` for delivering consumables or syncing with a backend.
- `Product` helpers: `periodText`, `monthlyPriceText`, `isEligibleForIntroOffer`.
- SwiftUI: `PurchaseButton`, `RestorePurchasesButton`.
- Example app `Examples/IAPExample` with `Products.storekit`.

[1.0.1]: https://github.com/nangnguyendev/IAP/releases/tag/1.0.1
[1.0.0]: https://github.com/nangnguyendev/IAP/releases/tag/1.0.0
