
import Foundation
import StoreKit

@objc(HWPSKMain) class SKMain : CDVPlugin, SKProductsRequestDelegate, SKRequestDelegate, SKPaymentTransactionObserver {
    // Cached Products
    var productById: [String: SKProduct] = [:]

    override func pluginInitialize() {
        print("pluginInitialize")

        // logPretty(productById, name: "productById")

        productById = [:]
        // logPretty(productById, name: "productById")
    }

    /* func greet(command: CDVInvokedUrlCommand) {
        let message = command.arguments[0] as! String

        print("Vasily" + message)

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: "Hello \(message)")
        commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
    }*/

    /* func doInit(command: CDVInvokedUrlCommand) {
        print("doInit")
        let result = SKPaymentQueue.canMakePayments()
        print("canMakePayments: \(result)")

        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsBool: result)
        commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
    }*/

    func restoreCompletedTransactions(_ command: CDVInvokedUrlCommand) {
        print("restoreCompletedTransactions")

        SKPaymentQueue.default().restoreCompletedTransactions()

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "ok")
        commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func getTransactions(_ command: CDVInvokedUrlCommand) {
        print("getTransactions")

        let transactions = SKPaymentQueue.default().transactions
        print("getTransactions count: \(transactions.count)")

        var tr: [[String: AnyObject]] = []

        for t in transactions {
            tr.append(serTransaction(t))
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: tr, options: JSONSerialization.WritingOptions(rawValue: 0))
            let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)!
            print("json: \(jsonString)")

            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonString as String)
            commandDelegate!.send(pluginResult, callbackId: command.callbackId)
        } catch {
            print("error default")
            return returnError(command, msg: "json error")
        }
    }

    /* func canMakePayments(command: CDVInvokedUrlCommand) {
        let result = SKPaymentQueue.canMakePayments()
        print("canMakePayments: \(result)")

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsBool: result)
        commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
    }*/

    func getProducts(_ command: CDVInvokedUrlCommand) {
        print("getProducts args: \(command.arguments)")

        logPretty(productById as AnyObject, name: "productById")

        // SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
        SKPaymentQueue.default().add(self)

        /* let productIds: Set<String> = [
            "com.naturalcycles.cordova.yearly3",
            "com.naturalcycles.cordova.monthly3",
            "com.naturalcycles.cordova.wrongly3",
        ]*/
        var productIds: Set<String> = []
        for a in command.arguments {
            productIds.insert(a as! String)
        }

        let productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productIds)
        productsRequest.delegate = self
        productsRequest.start()

        returnOk(command, msg: "")
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("callback from productsRequest")
        // print("didReceive: \(response.didR)")
        print(request)
        print(response)
        print("invalid size: \(response.invalidProductIdentifiers.count)")

        let canMakePayments = SKPaymentQueue.canMakePayments()
        print("canMakePayments: \(canMakePayments)")

        var products: [[String: AnyObject]] = []
        let invalidProductIdentifiers: [String] = response.invalidProductIdentifiers

        for a in response.invalidProductIdentifiers {
            print("invalid: \(a)")
        }

        for a in response.products {
            print("\(a.localizedTitle)")
            print("\(a.localizedDescription)")
            print("\(a.price)")
            print("\(a.priceLocale)")
            print("\(a.productIdentifier)")

            products.append(serProduct(a))
            productById[a.productIdentifier] = a
        }

        // commandDelegate!.evalJs("alert('bzzz10')")
        logPretty(products as AnyObject, name: "products")

        let details = [
            "canMakePayments": canMakePayments,
            "invalidProductIdentifiers": invalidProductIdentifiers,
            "products": products,
        ] as [String : Any]

        dispatchEvent("SKProductsResponse", details: details as AnyObject)
    }

    func refreshReceipt(_ command: CDVInvokedUrlCommand) {
        print("refreshReceipt")

        let req:SKReceiptRefreshRequest = SKReceiptRefreshRequest()
        req.delegate = self
        req.start()

        returnOk(command, msg: "")
    }

    func order(_ command: CDVInvokedUrlCommand) {
        print("order args: \(command.arguments)")

        let pid = command.arguments[0] as! String
        print("order: \(pid)")
        let product = productById[pid]

        if product == nil {
            return returnError(command, msg: "Product not found: \(pid)")
        }

        let payment = SKPayment(product: product!)
        SKPaymentQueue.default().add(payment)
        print("Added to queue: \(pid)")

        let orderRequest = SKRequest()
        orderRequest.delegate = self
        orderRequest.start()

        returnOk(command, msg: "")

        /*
        var productIds: Set<String> = [pid]

        let productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productIds)
        productsRequest.delegate = self
        productsRequest.start()

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)*/
    }

    func finishTransaction(_ command: CDVInvokedUrlCommand) {
        print("finishTransaction args: \(command.arguments)")

        let tid = command.arguments[0] as! String
        print("transId: \(tid)")

        // Try to find it
        print("getTransactions count: \(SKPaymentQueue.default().transactions.count)")

        var tr: SKPaymentTransaction?

        for t: SKPaymentTransaction in SKPaymentQueue.default().transactions {
            if t.transactionIdentifier! == tid {
                tr = t
                break
            }
        }

        if tr == nil {
            return returnError(command, msg: "Transaction not found")
        } else {
            SKPaymentQueue.default().finishTransaction(tr!)
            return returnOk(command, msg: "ok")
        }
    }

    func getReceipt(_ command: CDVInvokedUrlCommand) {
        print("getReceipt")

        let receiptUrl: URL? = Bundle.main.appStoreReceiptURL
        print("\(receiptUrl)")

        if receiptUrl == nil {
            print("receiptUrl is nil")
            return returnOk(command, msg: "") // empty string = no receipt
        }

        let receipt: Data? = try? Data(contentsOf: receiptUrl!)
        // print("\(receipt)")

        if receipt == nil {
            print("receipt is nil")
            return returnOk(command, msg: "") // empty string = no receipt
        }

        let receiptStr: NSString = receipt!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) as NSString
        print("\(receiptStr)")

        return returnOk(command, msg: "\(receiptStr)")
    }

    func receiptFound(_ receiptUrl: URL?) -> Bool {
        let receiptError: NSErrorPointer? = nil

        if let isReachable = (receiptUrl as NSURL?)?.checkResourceIsReachableAndReturnError(receiptError!) {
            return isReachable
        }

        return false
    }

    func requestDidFinish(_ request: SKRequest) {
        print("request finished: \(request)")

        let details = [AnyObject]()
        dispatchEvent("SKRequestDidFinish", details: details as AnyObject)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("request error: \(error)")

        let details = [
            "e": error.localizedDescription,
        ]

        dispatchEvent("SKError", details: details as AnyObject)
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("paymentQueue updatedTransactions!")
        print("paymentQueue callback count: \(transactions.count)")

        var trans: [[String: AnyObject]] = []
        for t in transactions {
            print("Trans: \(t)")
            print("Trans state: \(t.transactionState)")
            print("Trans state raw: \(t.transactionState.rawValue)")
            print("original: \(t.original)")
            print("Trans error: \(t.error)")
            print("Trans date: \(t.transactionDate)")
            print("Trans id: \(t.transactionIdentifier)")
            print("Trans payment: \(t.payment)")

            trans.append(serTransaction(t))
        }

        let details = [
            "transactions": trans,
        ]

        dispatchEvent("SKTransactionUpdated", details: details as AnyObject)
    }

    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        print("paymentQueue removedTransactions!")
        print("paymentQueue callback count: \(transactions.count)")

        var trans: [[String: AnyObject]] = []
        for t in transactions {
            print("Trans: \(t) \(t.transactionIdentifier) \(t.transactionState)")
            trans.append(serTransaction(t))
        }

        let details = [
                "transactions": trans,
        ]

        dispatchEvent("SKTransactionRemoved", details: details as AnyObject)
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("paymentQueue restoreCompletedTransactionsFailedWithError! \(error)")
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("paymentQueueRestoreCompletedTransactionsFinished")
    }

    func serProduct (_ p: SKProduct) -> [String: AnyObject] {
        let price = Int(p.price.multiplying(by: NSDecimalNumber(value: 100 as Int32)).int32Value)
        return [
            "localizedTitle": p.localizedTitle as AnyObject,
            "localizedDescription": p.localizedDescription as AnyObject,
            "price": price as AnyObject,
            "productIdentifier": p.productIdentifier as AnyObject,
            "localizedPrice": p.localizedPrice() as AnyObject,
            "currency": p.currency() as AnyObject,
            "country": p.country() as AnyObject,
        ]
    }

    func serTransaction (_ t: SKPaymentTransaction) -> [String: AnyObject] {
        var r: [String: AnyObject] = [
            // "transactionState": "\(t.transactionState)",
            "transactionState": "\(t.transactionState.rawValue)" as AnyObject,
            // "payment": t.payment,
        ]
        if t.error != nil {
            // Optional(Error Domain=SKErrorDomain Code=0 "Cannot connect to iTunes Store" UserInfo={NSLocalizedDescription=Cannot connect to iTunes Store})
            r["error"] = "\(t.error!.localizedDescription)" as AnyObject?
        }
        if t.transactionDate != nil {
            let tdate = Int(t.transactionDate!.timeIntervalSince1970)
            r["transactionDate"] = "\(tdate)" as AnyObject?
        }
        if t.transactionIdentifier != nil {
            r["transactionIdentifier"] = t.transactionIdentifier! as AnyObject?
        }
        if t.original != nil {
            r["originalTransaction"] = serTransaction(t.original!) as AnyObject?
        }

        return r
    }

    func returnOk (_ command: CDVInvokedUrlCommand, msg: String) {
        print("returnOk: \(msg)")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: msg)
        commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func returnError (_ command: CDVInvokedUrlCommand, msg: String) {
        print("returnError: \(msg)")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: msg)
        commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func dispatchEvent (_ eventName: String, details: AnyObject) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: details, options: JSONSerialization.WritingOptions(rawValue: 0))
            let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)!
            print("json: \(jsonString)")

            commandDelegate!.evalJs("window.dispatchEvent(new CustomEvent('\(eventName)', {detail: \(jsonString)}))")
        } catch let error as NSError {
            print("error:\n \(error.description)")
        } catch {
            print("error default")
        }
    }

    func logPretty (_ o: AnyObject, name: String) {
        print("logPretty \(name) started")
        do {
            let jsonData = try! JSONSerialization.data(withJSONObject: o, options: JSONSerialization.WritingOptions.prettyPrinted)
            let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)!
            print("\(name): \(jsonString)")
        } catch _ {
            print("exception in logPretty")
        }
    }
}
