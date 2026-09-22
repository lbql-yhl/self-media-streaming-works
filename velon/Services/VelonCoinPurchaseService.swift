//
//  VelonCoinPurchaseService.swift
//  velon
//

import Foundation
import os.log
import StoreKit

struct VelonCoinProduct: Equatable {
    let productId: String
    let displayName: String
    let coinAmount: Int
    let priceText: String
    let isPromotion: Bool
}

enum VelonCoinEconomy {
    static let startingBalance = 100
    static let digestAlbumShareCost = 10
}

final class VelonCoinPurchaseService: NSObject {
    static let shared = VelonCoinPurchaseService()

    static let catalog: [VelonCoinProduct] = [
        VelonCoinProduct(productId: "473900", displayName: "Palate Spark", coinAmount: 110, priceText: "$0.99", isPromotion: false),
        VelonCoinProduct(productId: "473901", displayName: "Street Bowl", coinAmount: 210, priceText: "$1.99", isPromotion: false),
        VelonCoinProduct(productId: "473902", displayName: "Lane Snack", coinAmount: 310, priceText: "$2.99", isPromotion: false),
        VelonCoinProduct(productId: "473903", displayName: "District Bite", coinAmount: 400, priceText: "$3.99", isPromotion: false),
        VelonCoinProduct(productId: "473904", displayName: "Market Tray", coinAmount: 520, priceText: "$4.99", isPromotion: false),
        VelonCoinProduct(productId: "473905", displayName: "Night Cart", coinAmount: 630, priceText: "$5.99", isPromotion: false),
        VelonCoinProduct(productId: "473906", displayName: "Harbor Plate", coinAmount: 740, priceText: "$6.99", isPromotion: false),
        VelonCoinProduct(productId: "473907", displayName: "City Feast", coinAmount: 1000, priceText: "$8.99", isPromotion: false),
        VelonCoinProduct(productId: "473908", displayName: "Route Bundle", coinAmount: 1200, priceText: "$9.99", isPromotion: false),
        VelonCoinProduct(productId: "473909", displayName: "Taste Atlas", coinAmount: 1600, priceText: "$12.99", isPromotion: false),
        VelonCoinProduct(productId: "473910", displayName: "Chef Circuit", coinAmount: 2000, priceText: "$15.99", isPromotion: false),
        VelonCoinProduct(productId: "473911", displayName: "Grand Tasting", coinAmount: 2600, priceText: "$19.99", isPromotion: false),
        VelonCoinProduct(productId: "473912", displayName: "Voyage Pantry", coinAmount: 3300, priceText: "$24.99", isPromotion: false),
        VelonCoinProduct(productId: "473913", displayName: "Empire Kitchen", coinAmount: 4200, priceText: "$29.99", isPromotion: false),
        VelonCoinProduct(productId: "473914", displayName: "World Table", coinAmount: 4900, priceText: "$34.99", isPromotion: false),
        VelonCoinProduct(productId: "473915", displayName: "Legend Menu", coinAmount: 6000, priceText: "$39.99", isPromotion: false),
        VelonCoinProduct(productId: "473916", displayName: "Crown Banquet", coinAmount: 8000, priceText: "$49.99", isPromotion: false),
        VelonCoinProduct(productId: "473917", displayName: "Odyssey Feast", coinAmount: 14000, priceText: "$79.99", isPromotion: false),
        VelonCoinProduct(productId: "473918", displayName: "Horizon Pantry", coinAmount: 14998, priceText: "$99.99", isPromotion: false),
        VelonCoinProduct(productId: "473919", displayName: "Promo Market", coinAmount: 520, priceText: "$1.99", isPromotion: true),
        VelonCoinProduct(productId: "473920", displayName: "Promo Cart", coinAmount: 800, priceText: "$2.99", isPromotion: true),
        VelonCoinProduct(productId: "473921", displayName: "Promo Route", coinAmount: 1300, priceText: "$4.99", isPromotion: true),
        VelonCoinProduct(productId: "473922", displayName: "Promo Atlas", coinAmount: 1500, priceText: "$5.99", isPromotion: true),
        VelonCoinProduct(productId: "473923", displayName: "Promo Circuit", coinAmount: 2700, priceText: "$11.99", isPromotion: true),
        VelonCoinProduct(productId: "473924", displayName: "Promo Voyage", coinAmount: 2900, priceText: "$12.99", isPromotion: true),
        VelonCoinProduct(productId: "473925", displayName: "Promo Crown", coinAmount: 7200, priceText: "$34.99", isPromotion: true),
        VelonCoinProduct(productId: "473926", displayName: "Promo Horizon", coinAmount: 17000, priceText: "$79.99", isPromotion: true)
    ]

    private let log = OSLog(subsystem: "velon", category: "iap")
    private let deliveredKey = "velon.iap.delivered"
    private var productsRequest: SKProductsRequest?
    private var purchaseCompletion: ((Result<Int, VelonPurchaseError>) -> Void)?
    private var pendingProductId: String?

    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    func purchase(productId: String, completion: @escaping (Result<Int, VelonPurchaseError>) -> Void) {
        guard SKPaymentQueue.canMakePayments() else {
            completion(.failure(.paymentsDisabled))
            return
        }
        guard Self.catalog.contains(where: { $0.productId == productId }) else {
            completion(.failure(.productUnavailable))
            return
        }
        if purchaseCompletion != nil {
            completion(.failure(.busy))
            return
        }
        purchaseCompletion = completion
        pendingProductId = productId
        let request = SKProductsRequest(productIdentifiers: [productId])
        request.delegate = self
        productsRequest = request
        request.start()
    }

    private var deliveredKeys: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: deliveredKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: deliveredKey) }
    }

    private func deliveryKey(for transaction: SKPaymentTransaction) -> String {
        if let id = transaction.transactionIdentifier, !id.isEmpty {
            return id
        }
        let date = transaction.transactionDate ?? Date()
        return "\(transaction.payment.productIdentifier)-\(date.timeIntervalSince1970)"
    }

    private func creditIfNeeded(transaction: SKPaymentTransaction) -> Int? {
        let key = deliveryKey(for: transaction)
        var keys = deliveredKeys
        if keys.contains(key) {
            os_log("duplicate_delivery_skipped %{public}@", log: log, type: .info, key)
            return VelonUserStore.shared.coinBalance
        }
        let productId = transaction.payment.productIdentifier
        guard let coins = Self.catalog.first(where: { $0.productId == productId })?.coinAmount, coins > 0 else {
            return nil
        }
        keys.insert(key)
        deliveredKeys = keys
        VelonUserStore.shared.coinBalance += coins
        return VelonUserStore.shared.coinBalance
    }

    private func clearPurchaseState() {
        purchaseCompletion = nil
        pendingProductId = nil
        productsRequest = nil
    }

    private func finish(_ transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    static func isUserCancellation(_ error: Error?) -> Bool {
        if let sk = error as? SKError, sk.code == .paymentCancelled { return true }
        let text = ((error?.localizedDescription ?? "") + "\(String(describing: error))").lowercased()
        let tokens = ["cancelled", "canceled", "user_cancelled", "skerrorpaymentcancelled", "paymentcancelled"]
        return tokens.contains { text.contains($0) }
    }
}

extension VelonCoinPurchaseService: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard let product = response.products.first else {
            DispatchQueue.main.async {
                self.purchaseCompletion?(.failure(.productUnavailable))
                self.clearPurchaseState()
            }
            return
        }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            if Self.isUserCancellation(error) {
                self.purchaseCompletion?(.failure(.cancelled))
            } else {
                os_log("product_request_failed %{public}@", log: self.log, type: .error, error.localizedDescription)
                self.purchaseCompletion?(.failure(.productUnavailable))
            }
            self.clearPurchaseState()
        }
    }
}

extension VelonCoinPurchaseService: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                DispatchQueue.main.async {
                    if let balance = self.creditIfNeeded(transaction: transaction) {
                        self.purchaseCompletion?(.success(balance))
                    } else {
                        self.purchaseCompletion?(.failure(.productUnavailable))
                    }
                    self.clearPurchaseState()
                    self.finish(transaction)
                }
            case .restored:
                // Consumable coin packs are not restored for credit.
                DispatchQueue.main.async {
                    self.finish(transaction)
                }
            case .failed:
                DispatchQueue.main.async {
                    if Self.isUserCancellation(transaction.error) {
                        self.purchaseCompletion?(.failure(.cancelled))
                    } else {
                        os_log("purchase_failed %{public}@", log: self.log, type: .error, transaction.error?.localizedDescription ?? "unknown")
                        self.purchaseCompletion?(.failure(.purchaseFailed))
                    }
                    self.clearPurchaseState()
                    self.finish(transaction)
                }
            case .purchasing, .deferred:
                break
            @unknown default:
                break
            }
        }
    }
}

enum VelonPurchaseError: Error {
    case paymentsDisabled
    case productUnavailable
    case purchaseFailed
    case cancelled
    case busy

    var userMessage: String? {
        switch self {
        case .paymentsDisabled:
            return "Purchases are disabled on this device. You can enable them in Settings."
        case .productUnavailable:
            return "This coin pack is unavailable right now. Please try again later."
        case .purchaseFailed:
            return "We could not complete the purchase. Please try again."
        case .cancelled:
            return nil
        case .busy:
            return "Another purchase is already in progress. Please wait a moment."
        }
    }
}
