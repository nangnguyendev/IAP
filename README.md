# IAP

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![Platforms](https://img.shields.io/badge/platforms-iOS%2015%20%7C%20macOS%2012%20%7C%20tvOS%2015%20%7C%20watchOS%208-blue.svg)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)

Swift Package tích hợp In-App Purchases (StoreKit 2) cho các app iOS.

- Tải sản phẩm, mua, khôi phục (restore), theo dõi quyền sở hữu (entitlements)
- Tự lắng nghe `Transaction.updates` (gia hạn, Ask to Buy, hoàn tiền…)
- Xác thực giao dịch (JWS) qua StoreKit 2
- `isPremium` sẵn dùng cho paywall
- Helper SwiftUI: `PurchaseButton`, `RestorePurchasesButton`
- Hỗ trợ: iOS 15+, macOS 12+, tvOS 15+, watchOS 8+

## Cài đặt

**Xcode:** File ▸ Add Package Dependencies… ▸ dán URL `https://github.com/nangnguyendev/IAP.git` ▸ Dependency Rule: *Up to Next Major Version* `1.0.0` ▸ chọn product `IAP`.

**Package.swift:**

```swift
dependencies: [
    .package(url: "https://github.com/nangnguyendev/IAP.git", from: "1.0.0")
],
targets: [
    .target(name: "MyApp", dependencies: ["IAP"])
]
```

## Sử dụng

### 1. Khởi tạo khi app chạy

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

### 2. Kiểm tra quyền premium

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
                    Text("\(perMonth) / tháng").font(.caption)
                }
            }
            RestorePurchasesButton("Khôi phục giao dịch")
        }
        .overlay { if iap.isLoadingProducts { ProgressView() } }
    }
}
```

### 4. Mua bằng code (UIKit hoặc logic riêng)

```swift
do {
    switch try await iap.purchase(productID: "com.myapp.lifetime") {
    case .success(let transaction): print("Đã mua", transaction.productID)
    case .pending:                  print("Đang chờ duyệt (Ask to Buy)")
    case .cancelled:                break
    }
} catch {
    print(error.localizedDescription)
}
```

### 5. Consumables / đồng bộ backend

Mặc định giao dịch được `finish()` tự động. Để cộng xu (consumable) hoặc gửi lên server trước khi finish:

```swift
iap.transactionHandler = { transaction in
    if transaction.productID == "com.myapp.coins100" {
        await CoinStore.shared.add(100)
    }
}
```

Nếu cần tự finish (ví dụ chờ server xác nhận), tạo cấu hình với `autoFinishTransactions: false` và gọi `await transaction.finish()` trong `transactionHandler` khi đã giao hàng xong.

### 6. Chỉ định sản phẩm nào là "premium"

```swift
IAPConfiguration(
    productIDs: ["pro.monthly", "pro.yearly", "remove_ads"],
    premiumProductIDs: ["pro.monthly", "pro.yearly"]   // remove_ads không tính là premium
)
```

## API chính

| Thành phần | Mô tả |
|---|---|
| `start()` | Bắt đầu lắng nghe giao dịch, tải sản phẩm và entitlements |
| `products`, `subscriptions`, `nonConsumables`, `consumables` | Danh sách sản phẩm (sắp xếp theo giá) |
| `purchase(_:)` / `purchase(productID:)` | Mua, trả về `PurchaseOutcome` |
| `restorePurchases()` | Gọi `AppStore.sync()` — chỉ dùng cho nút Restore |
| `isPremium`, `isPurchased(_:)`, `purchasedProductIDs` | Trạng thái sở hữu |
| `expirationDate(for:)` | Ngày hết hạn subscription |
| `showManageSubscriptions(in:)` | (iOS) Mở sheet quản lý subscription |
| `Product.periodText`, `.monthlyPriceText`, `.isEligibleForIntroOffer` | Helper hiển thị |

## App mẫu

`Examples/IAPExample` là app SwiftUI (iOS 16+) dùng package này qua đường dẫn local, kèm `Products.storekit` để test mà không cần App Store Connect:

| Product ID | Loại | Giá |
|---|---|---|
| `com.nguyennn.iapexample.pro.monthly` | Auto-renewable | $4.99 / tháng |
| `com.nguyennn.iapexample.pro.yearly` | Auto-renewable (trial 1 tuần) | $29.99 / năm |
| `com.nguyennn.iapexample.lifetime` | Non-consumable | $29.99 |
| `com.nguyennn.iapexample.removeads` | Non-consumable | $1.99 |
| `com.nguyennn.iapexample.coins100` / `coins500` | Consumable | $0.99 / $3.99 |

Chạy thử:

1. Mở `Examples/IAPExample/IAPExample.xcodeproj`.
2. Chọn scheme **IAPExample** và một simulator, rồi bấm Run. Scheme đã gán sẵn `Products.storekit`. Nếu danh sách sản phẩm trống, vào *Edit Scheme ▸ Run ▸ Options ▸ StoreKit Configuration* và chọn lại `Products.storekit`.
3. Thử các luồng: mua subscription/lifetime (trạng thái Premium chuyển sang Yes), mua xu (số xu tăng qua `transactionHandler`), Restore, Manage subscriptions, mở paywall.
4. Vào *Debug ▸ StoreKit ▸ Manage Transactions* để hoàn tiền, cho gia hạn nhanh, hoặc bật *Ask to Buy* để test trạng thái pending.

## Test trong app của bạn

1. Xcode ▸ File ▸ New ▸ File… ▸ **StoreKit Configuration File**, thêm các product ID giống trên App Store Connect.
2. Edit Scheme ▸ Run ▸ Options ▸ **StoreKit Configuration** ▸ chọn file vừa tạo.
3. Chạy app trên simulator — mua/hoàn tiền/gia hạn được giả lập qua *Debug ▸ StoreKit ▸ Manage Transactions*.

## Phát hành phiên bản

Package dùng [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`.

1. Ghi thay đổi vào `CHANGELOG.md`.
2. Commit, gắn tag rồi push:

```bash
git tag 1.1.0
git push origin main --tags
```

Các app đang dùng *Up to Next Major Version* sẽ nhận bản mới qua File ▸ Packages ▸ Update to Latest Package Versions.

## License

Phát hành theo giấy phép MIT. Xem [LICENSE](LICENSE).
