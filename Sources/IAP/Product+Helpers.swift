import StoreKit

public extension Product {
    var isAutoRenewable: Bool { type == .autoRenewable }

    var isEntitlement: Bool {
        type == .nonConsumable || type == .autoRenewable || type == .nonRenewable
    }

    var periodText: String? {
        subscription?.subscriptionPeriod.localizedText
    }

    var monthlyPriceText: String? {
        guard let period = subscription?.subscriptionPeriod else { return nil }
        let months: Decimal
        switch period.unit {
        case .day: months = Decimal(period.value) / 30
        case .week: months = Decimal(period.value) / 4
        case .month: months = Decimal(period.value)
        case .year: months = Decimal(period.value * 12)
        @unknown default: return nil
        }
        guard months > 0 else { return nil }
        return (price / months).formatted(priceFormatStyle)
    }

    var isEligibleForIntroOffer: Bool {
        get async {
            guard let subscription, subscription.introductoryOffer != nil else { return false }
            return await subscription.isEligibleForIntroOffer
        }
    }
}

public extension Product.SubscriptionPeriod {
    var localizedText: String {
        let component: Calendar.Component
        switch unit {
        case .day: component = .day
        case .week: component = .weekOfMonth
        case .month: component = .month
        case .year: component = .year
        @unknown default: component = .day
        }
        var dateComponents = DateComponents()
        dateComponents.setValue(value, for: component)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        return formatter.string(from: dateComponents) ?? "\(value)"
    }
}
