//
//  Errors.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import Foundation
import web3swift

enum GeneralErrors: Error {
    case noKey
    case noPassword
    case wrongPassword
    case decodingError
}

enum WalletSavingError: Error {
    case couldNotSaveTheWallet
    case couldNotCreateTheWallet
    case couldNotGetTheWallet
    case couldNotGetAddress
    case couldNotGetThePrivateKey
    case couldNotDeleteTheWallet
}

enum SendEthErrors: Error {
    case invalidDestinationAddress
    case invalidAmountFormat
    case emptyDestinationAddress
    case emptyAmount
    case contractLoadingError
    case retrievingGasPriceError
    case retrievingEstimatedGasError
    case emptyResult
    case noAvailableKeys
    case createTransactionIssue
    case zeroAmount
    case insufficientFund
    case retrievingCurrentAddressError
}

enum AccountContractErrors: Error {
    case contractLoadingError
    case instantiateContractError
}

enum ResetPasswordError: Error {
    case failureToFetchOldPassword
    case failureToRegeneratePassword
}

enum FileError: Error {
    case fileNotFound(name: String)
    case fileDecodingFailed(name: String, Swift.Error)
}

enum FileUploadError: Error {
    case fileNotAvailable
    case userNotLoggedIn
    case fileManagerError(String)
}
enum APIError: Error, LocalizedError {
    
    enum HTTPStatusCode: Int, Error, CustomStringConvertible {
        // 100 Informational
        case `continue` = 100
        case switchingProtocols
        case processing
        // 200 Success
        case ok = 200
        case created
        case accepted
        case nonAuthoritativeInformation
        case noContent
        case resetContent
        case partialContent
        case multiStatus
        case alreadyReported
        case iMUsed = 226
        // 300 Redirection
        case multipleChoices = 300
        case movedPermanently
        case found
        case seeOther
        case notModified
        case useProxy
        case switchProxy
        case temporaryRedirect
        case permanentRedirect
        // 400 Client Error
        case badRequest = 400
        case unauthorized
        case paymentRequired
        case forbidden
        case notFound
        case methodNotAllowed
        case notAcceptable
        case proxyAuthenticationRequired
        case requestTimeout
        case conflict
        case gone
        case lengthRequired
        case preconditionFailed
        case payloadTooLarge
        case uriTooLong
        case unsupportedMediaType
        case rangeNotSatisfiable
        case expectationFailed
        case imATeapot
        case misdirectedRequest = 421
        case unprocessableEntity
        case locked
        case failedDependency
        case upgradeRequired = 426
        case preconditionRequired = 428
        case tooManyRequests
        case requestHeaderFieldsTooLarge = 431
        case unavailableForLegalReasons = 451
        // 500 Server Error
        case internalServerError = 500
        case notImplemented
        case badGateway
        case serviceUnavailable
        case gatewayTimeout
        case httpVersionNotSupported
        case variantAlsoNegotiates
        case insufficientStorage
        case loopDetected
        case notExtended = 510
        case networkAuthenticationRequired
        
        var description: String {
            // HTTPURLResponse.localizedString(forStatusCode: rawValue)
            return NSLocalizedString(
                "HTTP status: \(rawValue)",
                tableName: "HttpStatusEnum",
                comment: ""
            )
        }
    }
    
    case decodingError
    case unknown
    case generalError(reason: String)
    case networkError(from: URLError)
}

enum PostingError: Error {
    case generalError(reason: String)
    case invalidDestinationAddress
    case invalidAmountFormat
    case emptyDestinationAddress
    case emptyAmount
    case contractLoadingError
    case retrievingGasPriceError
    case retrievingEstimatedGasError
    case emptyResult
    case noAvailableKeys
    case createTransactionIssue
    case zeroAmount
    case insufficientFund(String)
    case retrievingCurrentAddressError
    case web3Error(Web3Error)
    case apiError(APIError)
    case fileUploadError(FileUploadError)
}
