
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

    func restoreCompletedTransactions(command: CDVInvokedUrlCommand) {
        print("restoreCompletedTransactions")

        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: "ok")
        commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
    }

    func getTransactions(command: CDVInvokedUrlCommand) {
        print("getTransactions")

        let transactions = SKPaymentQueue.defaultQueue().transactions
        print("getTransactions count: \(transactions.count)")

        var tr: [[String: AnyObject]] = []

        for t in transactions {
            tr.append(serTransaction(t))
        }

        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(tr, options: NSJSONWritingOptions(rawValue: 0))
            let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)!
            print("json: \(jsonString)")

            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: jsonString as String)
            commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
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

    func getProducts(command: CDVInvokedUrlCommand) {
        print("getProducts args: \(command.arguments)")

        logPretty(productById, name: "productById")

        // SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)

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

    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
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
        logPretty(products, name: "products")

        let details = [
            "canMakePayments": canMakePayments,
            "invalidProductIdentifiers": invalidProductIdentifiers,
            "products": products,
        ]

        dispatchEvent("SKProductsResponse", details: details)
    }

    func refreshReceipt(command: CDVInvokedUrlCommand) {
        print("refreshReceipt")

        let req:SKReceiptRefreshRequest = SKReceiptRefreshRequest()
        req.delegate = self
        req.start()

        returnOk(command, msg: "")
    }

    func order(command: CDVInvokedUrlCommand) {
        print("order args: \(command.arguments)")

        let pid = command.arguments[0] as! String
        print("order: \(pid)")
        let product = productById[pid]

        if product == nil {
            return returnError(command, msg: "Product not found: \(pid)")
        }

        let payment = SKPayment(product: product!)
        SKPaymentQueue.defaultQueue().addPayment(payment)
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

    func finishTransaction(command: CDVInvokedUrlCommand) {
        print("finishTransaction args: \(command.arguments)")

        let tid = command.arguments[0] as! String
        print("transId: \(tid)")

        // Try to find it
        print("getTransactions count: \(SKPaymentQueue.defaultQueue().transactions.count)")

        var tr: SKPaymentTransaction?

        for t: SKPaymentTransaction in SKPaymentQueue.defaultQueue().transactions {
            if t.transactionIdentifier! == tid {
                tr = t
                break
            }
        }

        if tr == nil {
            return returnError(command, msg: "Transaction not found")
        } else {
            SKPaymentQueue.defaultQueue().finishTransaction(tr!)
            return returnOk(command, msg: "ok")
        }
    }

    func getReceipt(command: CDVInvokedUrlCommand) {
        print("getReceipt")

        let receiptUrl: NSURL? = NSBundle.mainBundle().appStoreReceiptURL
        print("\(receiptUrl)")

        if receiptUrl == nil {
            print("receiptUrl is nil")
            return returnOk(command, msg: "") // empty string = no receipt
        }

        let receipt: NSData? = NSData(contentsOfURL: receiptUrl!)
        // print("\(receipt)")

        if receipt == nil {
            print("receipt is nil")
            return returnOk(command, msg: "") // empty string = no receipt
        }

        let receiptStr: NSString = receipt!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        print("\(receiptStr)")

        return returnOk(command, msg: "\(receiptStr)")
    }

    func receiptFound(receiptUrl: NSURL?) -> Bool {
        let receiptError: NSErrorPointer = nil

        if let isReachable = receiptUrl?.checkResourceIsReachableAndReturnError(receiptError) {
            return isReachable
        }

        return false
    }

    func requestDidFinish(request: SKRequest) {
        print("request finished: \(request)")

        let details = []
        dispatchEvent("SKRequestDidFinish", details: details)
    }

    func request(request: SKRequest, didFailWithError error: NSError) {
        print("request error: \(error)")

        let details = [
            "e": error.localizedDescription,
        ]

        dispatchEvent("SKError", details: details)
    }

    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("paymentQueue updatedTransactions!")
        print("paymentQueue callback count: \(transactions.count)")

        var trans: [[String: AnyObject]] = []
        for t in transactions {
            print("Trans: \(t)")
            print("Trans state: \(t.transactionState)")
            print("Trans state raw: \(t.transactionState.rawValue)")
            print("original: \(t.originalTransaction)")
            print("Trans error: \(t.error)")
            print("Trans date: \(t.transactionDate)")
            print("Trans id: \(t.transactionIdentifier)")
            print("Trans payment: \(t.payment)")

            trans.append(serTransaction(t))
        }

        let details = [
            "transactions": trans,
        ]

        dispatchEvent("SKTransactionUpdated", details: details)
    }

    func paymentQueue(queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
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

        dispatchEvent("SKTransactionRemoved", details: details)
    }

    func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        print("paymentQueue restoreCompletedTransactionsFailedWithError! \(error)")
    }

    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        print("paymentQueueRestoreCompletedTransactionsFinished")
    }

    func serProduct (p: SKProduct) -> [String: AnyObject] {
        let price = Int(p.price.decimalNumberByMultiplyingBy(NSDecimalNumber(int: 100)).intValue)
        return [
            "localizedTitle": p.localizedTitle,
            "localizedDescription": p.localizedDescription,
            "price": price,
            "productIdentifier": p.productIdentifier,
            "localizedPrice": p.localizedPrice(),
            "currency": p.currency(),
            "country": p.country(),
        ]
    }

    func serTransaction (t: SKPaymentTransaction) -> [String: AnyObject] {
        var r: [String: AnyObject] = [
            // "transactionState": "\(t.transactionState)",
            "transactionState": "\(t.transactionState.rawValue)",
            // "payment": t.payment,
        ]
        if t.error != nil {
            // Optional(Error Domain=SKErrorDomain Code=0 "Cannot connect to iTunes Store" UserInfo={NSLocalizedDescription=Cannot connect to iTunes Store})
            r["error"] = "\(t.error!.localizedDescription)"
        }
        if t.transactionDate != nil {
            let tdate = Int(t.transactionDate!.timeIntervalSince1970)
            r["transactionDate"] = "\(tdate)"
        }
        if t.transactionIdentifier != nil {
            r["transactionIdentifier"] = t.transactionIdentifier!
        }
        if t.originalTransaction != nil {
            r["originalTransaction"] = serTransaction(t.originalTransaction!)
        }

        return r
    }

    func returnOk (command: CDVInvokedUrlCommand, msg: String) {
        print("returnOk: \(msg)")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: msg)
        commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
    }

    func returnError (command: CDVInvokedUrlCommand, msg: String) {
        print("returnError: \(msg)")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: msg)
        commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
    }

    func dispatchEvent (eventName: String, details: AnyObject) {
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(details, options: NSJSONWritingOptions(rawValue: 0))
            let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)!
            print("json: \(jsonString)")

            commandDelegate!.evalJs("window.dispatchEvent(new CustomEvent('\(eventName)', {detail: \(jsonString)}))")
        } catch let error as NSError {
            print("error:\n \(error.description)")
        } catch {
            print("error default")
        }
    }

    func logPretty (o: AnyObject, name: String) {
        print("logPretty \(name) started")
        do {
            let jsonData = try! NSJSONSerialization.dataWithJSONObject(o, options: NSJSONWritingOptions.PrettyPrinted)
            let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)!
            print("\(name): \(jsonString)")
        } catch _ {
            print("exception in logPretty")
        }
    }
}
