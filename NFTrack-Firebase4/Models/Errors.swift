//
//  Errors.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-10.
//

import Foundation

enum Errors: Error {
    case noKey
    case noPassword
    case wrongPassword
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
