# Changelog

## [1.0.0] - 2026-10-19

### Added
- `IAPManager` dựa trên StoreKit 2: tải sản phẩm, mua, restore, theo dõi entitlements.
- Tự lắng nghe `Transaction.updates` và xử lý `Transaction.unfinished` khi khởi động.
- `IAPConfiguration` với `premiumProductIDs` và `autoFinishTransactions`.
- `transactionHandler` để giao consumable hoặc đồng bộ backend.
- Helper `Product`: `periodText`, `monthlyPriceText`, `isEligibleForIntroOffer`.
- SwiftUI: `PurchaseButton`, `RestorePurchasesButton`.
- App mẫu `Examples/IAPExample` kèm `Products.storekit`.

[1.0.0]: https://github.com/nangnguyendev/IAP/releases/tag/1.0.0
