import StoreKit

extension SKProduct {
    func localizedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)!
    }

    func currency() -> String {
        let formatter = NumberFormatter()
        formatter.locale = self.priceLocale
        return formatter.internationalCurrencySymbol
        // return self.priceLocale.objectForKey(NSLocaleCurrencySymbol) as! String
    }

    func country() -> String {
        return (self.priceLocale as NSLocale).object(forKey: NSLocale.Key.countryCode) as! String
    }
}
