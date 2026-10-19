import Testing
@testable import IAP

@Test func configurationDefaults() {
    let config = IAPConfiguration(productIDs: ["a", "b"])
    #expect(config.productIDs == ["a", "b"])
    #expect(config.premiumProductIDs == nil)
    #expect(config.autoFinishTransactions)
}

@MainActor
@Test func managerInitialState() {
    let manager = IAPManager(productIDs: ["com.example.pro"])
    #expect(manager.products.isEmpty)
    #expect(manager.purchasedProductIDs.isEmpty)
    #expect(!manager.isPremium)
    #expect(!manager.isPurchased("com.example.pro"))
    #expect(manager.product(for: "com.example.pro") == nil)
}

@Test func errorDescriptions() {
    #expect(IAPError.productNotFound("x").errorDescription == "Product \"x\" is not available.")
    #expect(IAPError.failedVerification.errorDescription != nil)
    #expect(IAPError.purchasesNotAllowed.errorDescription != nil)
}
