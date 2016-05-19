import StoreKit

extension SKProduct {
    func localizedPrice() -> String {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        formatter.locale = self.priceLocale
        return formatter.stringFromNumber(self.price)!
    }

    func currency() -> String {
        /* let formatter = NSNumberFormatter()
        formatter.locale = self.priceLocale
        return formatter.internationalCurrencySymbol*/
        return self.priceLocale.objectForKey(NSLocaleCurrencySymbol) as! String
    }

    func country() -> String {
        return self.priceLocale.objectForKey(NSLocaleCountryCode) as! String
    }
}
