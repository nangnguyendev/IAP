import IAP
import SwiftUI

@main
struct IAPExampleApp: App {
    @StateObject private var iap: IAPManager
    @StateObject private var wallet: CoinWallet

    init() {
        let wallet = CoinWallet()
        let iap = IAPManager(configuration: IAPConfiguration(
            productIDs: ProductID.all,
            premiumProductIDs: ProductID.premium
        ))
        iap.transactionHandler = { transaction in
            guard transaction.revocationDate == nil,
                  let amount = ProductID.coinAmounts[transaction.productID] else { return }
            wallet.add(amount)
        }
        _iap = StateObject(wrappedValue: iap)
        _wallet = StateObject(wrappedValue: wallet)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(iap)
                .environmentObject(wallet)
                .task { await iap.start() }
        }
    }
}
