//
//  ERC721PresetABI.swift
//  NFTrack-Firebase4
//
//  Created by J C on 2021-05-13.
//

import Foundation
import web3swift

// 0x9A9C30E27FC797c287847bA37255c15940A081a2
// 0x16bcb424E5C124CB5cB7AbBC79589B7Fe67C92d6


// MARK: - erc721ContractAddress
let erc721ContractAddress = EthereumAddress("0x656f9bf02fa8eff800f383e5678e699ce2788c5c")

let ERC721PresetMinterPauserAutoIdContractAddress = EthereumAddress("0x16bcb424E5C124CB5cB7AbBC79589B7Fe67C92d6")

// MARK: - ERC721PresetMinterPauserAutoIdABI
let ERC721PresetMinterPauserAutoIdABI = """
[
{
"inputs": [
{
"internalType": "string",
"name": "name",
"type": "string"
},
{
"internalType": "string",
"name": "symbol",
"type": "string"
},
{
"internalType": "string",
"name": "baseTokenURI",
"type": "string"
}
],
"stateMutability": "nonpayable",
"type": "constructor"
},
{
"anonymous": false,
"inputs": [
{
"indexed": true,
"internalType": "address",
"name": "owner",
"type": "address"
},
{
"indexed": true,
"internalType": "address",
"name": "approved",
"type": "address"
},
{
"indexed": true,
"internalType": "uint256",
"name": "tokenId",
"type": "uint256"
}
],
"name": "Approval",
"type": "event"
},
{
"anonymous": false,
"inputs": [
{
"indexed": true,
"internalType": "address",
"name": "owner",
"type": "address"
},
{
"indexed": true,
"internalType": "address",
"name": "operator",
"type": "address"
},
{
"indexed": false,
"internalType": "bool",
"name": "approved",
"type": "bool"
}
],
"name": "ApprovalForAll",
"type": "event"
},
{
"anonymous": false,
"inputs": [
{
"indexed": false,
"internalType": "address",
"name": "account",
"type": "address"
}
],
"name": "Paused",
"type": "event"
},
{
"anonymous": false,
"inputs": [
{
"indexed": true,
"internalType": "bytes32",
"name": "role",
"type": "bytes32"
},
{
"indexed": true,
"internalType": "bytes32",
"name": "previousAdminRole",
"type": "bytes32"
},
{
"indexed": true,
"internalType": "bytes32",
"name": "newAdminRole",
"type": "bytes32"
}
],
"name": "RoleAdminChanged",
"type": "event"
},
{
"anonymous": false,
"inputs": [
{
"indexed": true,
"internalType": "bytes32",
"name": "role",
"type": "bytes32"
},
{
"indexed": true,
"internalType": "address",
"name": "account",
"type": "address"
},
{
"indexed": true,
"internalType": "address",
"name": "sender",
"type": "address"
}
],
"name": "RoleGranted",
"type": "event"
},
{
"anonymous": false,
"inputs": [
{
"indexed": true,
"internalType": "bytes32",
"name": "role",
"type": "bytes32"
},
{
"indexed": true,
"internalType": "address",
"name": "account",
"type": "address"
},
{
"indexed": true,
"internalType": "address",
"name": "sender",
"type": "address"
}
],
"name": "RoleRevoked",
"type": "event"
},
{
"anonymous": false,
"inputs": [
{
"indexed": true,
"internalType": "address",
"name": "from",
"type": "address"
},
{
"indexed": true,
"internalType": "address",
"name": "to",
"type": "address"
},
{
"indexed": true,
"internalType": "uint256",
"name": "tokenId",
"type": "uint256"
}
],
"name": "Transfer",
"type": "event"
},
{
"anonymous": false,
"inputs": [
{
"indexed": false,
"internalType": "address",
"name": "account",
"type": "address"
}
],
"name": "Unpaused",
"type": "event"
},
{
"inputs": [],
"name": "DEFAULT_ADMIN_ROLE",
"outputs": [
{
"internalType": "bytes32",
"name": "",
"type": "bytes32"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [],
"name": "MINTER_ROLE",
"outputs": [
{
"internalType": "bytes32",
"name": "",
"type": "bytes32"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [],
"name": "PAUSER_ROLE",
"outputs": [
{
"internalType": "bytes32",
"name": "",
"type": "bytes32"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [
{
"internalType": "address",
"name": "to",
"type": "address"
},
{
"internalType": "uint256",
"name": "tokenId",
"type": "uint256"
}
],
"name": "approve",
"outputs": [],
"stateMutability": "nonpayable",
"type": "function"
},
{
"inputs": [
{
"internalType": "address",
"name": "owner",
"type": "address"
}
],
"name": "balanceOf",
"outputs": [
{
"internalType": "uint256",
"name": "",
"type": "uint256"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [
{
"internalType": "uint256",
"name": "tokenId",
"type": "uint256"
}
],
"name": "burn",
"outputs": [],
"stateMutability": "nonpayable",
"type": "function"
},
{
"inputs": [
{
"internalType": "uint256",
"name": "tokenId",
"type": "uint256"
}
],
"name": "getApproved",
"outputs": [
{
"internalType": "address",
"name": "",
"type": "address"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [
{
"internalType": "bytes32",
"name": "role",
"type": "bytes32"
}
],
"name": "getRoleAdmin",
"outputs": [
{
"internalType": "bytes32",
"name": "",
"type": "bytes32"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [
{
"internalType": "bytes32",
"name": "role",
"type": "bytes32"
},
{
"internalType": "uint256",
"name": "index",
"type": "uint256"
}
],
"name": "getRoleMember",
"outputs": [
{
"internalType": "address",
"name": "",
"type": "address"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [
{
"internalType": "bytes32",
"name": "role",
"type": "bytes32"
}
],
"name": "getRoleMemberCount",
"outputs": [
{
"internalType": "uint256",
"name": "",
"type": "uint256"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [
{
"internalType": "bytes32",
"name": "role",
"type": "bytes32"
},
{
"internalType": "address",
"name": "account",
"type": "address"
}
],
"name": "grantRole",
"outputs": [],
"stateMutability": "nonpayable",
"type": "function"
},
{
"inputs": [
{
"internalType": "bytes32",
"name": "role",
"type": "bytes32"
},
{
"internalType": "address",
"name": "account",
"type": "address"
}
],
"name": "hasRole",
"outputs": [
{
"internalType": "bool",
"name": "",
"type": "bool"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [
{
"internalType": "address",
"name": "owner",
"type": "address"
},
{
"internalType": "address",
"name": "operator",
"type": "address"
}
],
"name": "isApprovedForAll",
"outputs": [
{
"internalType": "bool",
"name": "",
"type": "bool"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [
{
"internalType": "address",
"name": "to",
"type": "address"
}
],
"name": "mint",
"outputs": [],
"stateMutability": "nonpayable",
"type": "function"
},
{
"inputs": [],
"name": "name",
"outputs": [
{
"internalType": "string",
"name": "",
"type": "string"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [
{
"internalType": "uint256",
"name": "tokenId",
"type": "uint256"
}
],
"name": "ownerOf",
"outputs": [
{
"internalType": "address",
"name": "",
"type": "address"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [],
"name": "pause",
"outputs": [],
"stateMutability": "nonpayable",
"type": "function"
},
{
"inputs": [],
"name": "paused",
"outputs": [
{
"internalType": "bool",
"name": "",
"type": "bool"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [
{
"internalType": "bytes32",
"name": "role",
"type": "bytes32"
},
{
"internalType": "address",
"name": "account",
"type": "address"
}
],
"name": "renounceRole",
"outputs": [],
"stateMutability": "nonpayable",
"type": "function"
},
{
"inputs": [
{
"internalType": "bytes32",
"name": "role",
"type": "bytes32"
},
{
"internalType": "address",
"name": "account",
"type": "address"
}
],
"name": "revokeRole",
"outputs": [],
"stateMutability": "nonpayable",
"type": "function"
},
{
"inputs": [
{
"internalType": "address",
"name": "from",
"type": "address"
},
{
"internalType": "address",
"name": "to",
"type": "address"
},
{
"internalType": "uint256",
"name": "tokenId",
"type": "uint256"
}
],
"name": "safeTransferFrom",
"outputs": [],
"stateMutability": "nonpayable",
"type": "function"
},
{
"inputs": [
{
"internalType": "address",
"name": "from",
"type": "address"
},
{
"internalType": "address",
"name": "to",
"type": "address"
},
{
"internalType": "uint256",
"name": "tokenId",
"type": "uint256"
},
{
"internalType": "bytes",
"name": "_data",
"type": "bytes"
}
],
"name": "safeTransferFrom",
"outputs": [],
"stateMutability": "nonpayable",
"type": "function"
},
{
"inputs": [
{
"internalType": "address",
"name": "operator",
"type": "address"
},
{
"internalType": "bool",
"name": "approved",
"type": "bool"
}
],
"name": "setApprovalForAll",
"outputs": [],
"stateMutability": "nonpayable",
"type": "function"
},
{
"inputs": [
{
"internalType": "bytes4",
"name": "interfaceId",
"type": "bytes4"
}
],
"name": "supportsInterface",
"outputs": [
{
"internalType": "bool",
"name": "",
"type": "bool"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [],
"name": "symbol",
"outputs": [
{
"internalType": "string",
"name": "",
"type": "string"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [
{
"internalType": "uint256",
"name": "index",
"type": "uint256"
}
],
"name": "tokenByIndex",
"outputs": [
{
"internalType": "uint256",
"name": "",
"type": "uint256"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [
{
"internalType": "address",
"name": "owner",
"type": "address"
},
{
"internalType": "uint256",
"name": "index",
"type": "uint256"
}
],
"name": "tokenOfOwnerByIndex",
"outputs": [
{
"internalType": "uint256",
"name": "",
"type": "uint256"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [
{
"internalType": "uint256",
"name": "tokenId",
"type": "uint256"
}
],
"name": "tokenURI",
"outputs": [
{
"internalType": "string",
"name": "",
"type": "string"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [],
"name": "totalSupply",
"outputs": [
{
"internalType": "uint256",
"name": "",
"type": "uint256"
}
],
"stateMutability": "view",
"type": "function",
"constant": true
},
{
"inputs": [
{
"internalType": "address",
"name": "from",
"type": "address"
},
{
"internalType": "address",
"name": "to",
"type": "address"
},
{
"internalType": "uint256",
"name": "tokenId",
"type": "uint256"
}
],
"name": "transferFrom",
"outputs": [],
"stateMutability": "nonpayable",
"type": "function"
},
{
"inputs": [],
"name": "unpause",
"outputs": [],
"stateMutability": "nonpayable",
"type": "function"
}
]
"""

// MARK: - purchaseABI
let purchaseABI = """
[
    {
        "inputs": [],
        "name": "abort",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "confirmPurchase",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "confirmReceived",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "stateMutability": "payable",
        "type": "constructor"
    },
    {
        "inputs": [],
        "name": "InvalidState",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "OnlyBuyer",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "OnlySeller",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "ValueNotEven",
        "type": "error"
    },
    {
        "anonymous": false,
        "inputs": [],
        "name": "Aborted",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [],
        "name": "ItemReceived",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [],
        "name": "PurchaseConfirmed",
        "type": "event"
    },
    {
        "inputs": [],
        "name": "refundSeller",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "anonymous": false,
        "inputs": [],
        "name": "SellerRefunded",
        "type": "event"
    },
    {
        "inputs": [],
        "name": "buyer",
        "outputs": [
            {
                "internalType": "address payable",
                "name": "",
                "type": "address"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "seller",
        "outputs": [
            {
                "internalType": "address payable",
                "name": "",
                "type": "address"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "state",
        "outputs": [
            {
                "internalType": "enum Purchase.State",
                "name": "",
                "type": "uint8"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "value",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
]
"""

// MARK: - purchaseBytecode
let purchaseBytecode = """
608060405233600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060023461005291906100a4565b60008190555034600054600261006891906100d5565b1461009f576040517fbe3e4c4200000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b610197565b60006100af8261012f565b91506100ba8361012f565b9250826100ca576100c9610168565b5b828204905092915050565b60006100e08261012f565b91506100eb8361012f565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff048311821515161561012457610123610139565b5b828202905092915050565b6000819050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b610be580620001a76000396000f3fe60806040526004361061007b5760003560e01c806373fac6f01161004e57806373fac6f014610118578063c19d93fb1461012f578063c7981b1b1461015a578063d6960697146101715761007b565b806308551a531461008057806335a063b4146100ab5780633fa4f245146100c25780637150d8ae146100ed575b600080fd5b34801561008c57600080fd5b5061009561017b565b6040516100a29190610a31565b60405180910390f35b3480156100b757600080fd5b506100c06101a1565b005b3480156100ce57600080fd5b506100d76103cb565b6040516100e49190610a67565b60405180910390f35b3480156100f957600080fd5b506101026103d1565b60405161010f9190610a31565b60405180910390f35b34801561012457600080fd5b5061012d6103f7565b005b34801561013b57600080fd5b50610144610622565b6040516101519190610a4c565b60405180910390f35b34801561016657600080fd5b5061016f610635565b005b61017961086d565b005b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610228576040517f85d1f72600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6000806003811115610263577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b600260149054906101000a900460ff1660038111156102ab577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b146102e2576040517fbaf3f0f700000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b7f72c874aeff0b183a56e2b79c71b46e1aed4dee5e09862134b8821ba2fddbf8bf60405160405180910390a16003600260146101000a81548160ff0219169083600381111561035a577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b0217905550600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166108fc479081150290604051600060405180830381858888f193505050501580156103c7573d6000803e3d6000fd5b5050565b60005481565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461047e576040517f86efbb5500000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60018060038111156104b9577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b600260149054906101000a900460ff166003811115610501577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b14610538576040517fbaf3f0f700000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b7fe89152acd703c9d8c7d28829d443260b411454d45394e7995815140c8cbcbcf760405160405180910390a160028060146101000a81548160ff021916908360038111156105af577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b0217905550600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166108fc6000549081150290604051600060405180830381858888f1935050505015801561061e573d6000803e3d6000fd5b5050565b600260149054906101000a900460ff1681565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146106bc576040517f85d1f72600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60028060038111156106f7577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b600260149054906101000a900460ff16600381111561073f577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b14610776576040517fbaf3f0f700000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b7ffda69c32bcfdba840a167777906b173b607eb8b4d8853b97a80d26e613d858db60405160405180910390a16003600260146101000a81548160ff021916908360038111156107ee577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b0217905550600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166108fc600054600361083e9190610a82565b9081150290604051600060405180830381858888f19350505050158015610869573d6000803e3d6000fd5b5050565b60008060038111156108a8577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b600260149054906101000a900460ff1660038111156108f0577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b14610927576040517fbaf3f0f700000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60005460026109369190610a82565b34148061094257600080fd5b7fd5d55c8a68912e9a110618df8d5e2e83b8d83211c57a8ddd1203df92885dc88160405160405180910390a133600260006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506001600260146101000a81548160ff021916908360038111156109fb577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b02179055505050565b610a0d81610adc565b82525050565b610a1c81610b2b565b82525050565b610a2b81610b21565b82525050565b6000602082019050610a466000830184610a04565b92915050565b6000602082019050610a616000830184610a13565b92915050565b6000602082019050610a7c6000830184610a22565b92915050565b6000610a8d82610b21565b9150610a9883610b21565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0483118215151615610ad157610ad0610b3d565b5b828202905092915050565b6000610ae782610b01565b9050919050565b6000819050610afc82610b9b565b919050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000819050919050565b6000610b3682610aee565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b60048110610bac57610bab610b6c565b5b5056fea2646970667358221220abec5d1083acf78017eb4db3ecdbd3c0f263111133c6896d1c45ed74bf0ee16f64736f6c63430008040033
"""





// MARK: - contractBytecode2

let contractBytecode2 = """
{
"generatedSources": [
{
"ast": {
"nodeType": "YulBlock",
"src": "0:1004:1",
"statements": [
{
"body": {
"nodeType": "YulBlock",
"src": "49:143:1",
"statements": [
{
"nodeType": "YulAssignment",
"src": "59:25:1",
"value": {
"arguments": [
{
"name": "x",
"nodeType": "YulIdentifier",
"src": "82:1:1"
}
],
"functionName": {
"name": "cleanup_t_uint256",
"nodeType": "YulIdentifier",
"src": "64:17:1"
},
"nodeType": "YulFunctionCall",
"src": "64:20:1"
},
"variableNames": [
{
"name": "x",
"nodeType": "YulIdentifier",
"src": "59:1:1"
}
]
},
{
"nodeType": "YulAssignment",
"src": "93:25:1",
"value": {
"arguments": [
{
"name": "y",
"nodeType": "YulIdentifier",
"src": "116:1:1"
}
],
"functionName": {
"name": "cleanup_t_uint256",
"nodeType": "YulIdentifier",
"src": "98:17:1"
},
"nodeType": "YulFunctionCall",
"src": "98:20:1"
},
"variableNames": [
{
"name": "y",
"nodeType": "YulIdentifier",
"src": "93:1:1"
}
]
},
{
"body": {
"nodeType": "YulBlock",
"src": "140:22:1",
"statements": [
{
"expression": {
"arguments": [],
"functionName": {
"name": "panic_error_0x12",
"nodeType": "YulIdentifier",
"src": "142:16:1"
},
"nodeType": "YulFunctionCall",
"src": "142:18:1"
},
"nodeType": "YulExpressionStatement",
"src": "142:18:1"
}
]
},
"condition": {
"arguments": [
{
"name": "y",
"nodeType": "YulIdentifier",
"src": "137:1:1"
}
],
"functionName": {
"name": "iszero",
"nodeType": "YulIdentifier",
"src": "130:6:1"
},
"nodeType": "YulFunctionCall",
"src": "130:9:1"
},
"nodeType": "YulIf",
"src": "127:2:1"
},
{
"nodeType": "YulAssignment",
"src": "172:14:1",
"value": {
"arguments": [
{
"name": "x",
"nodeType": "YulIdentifier",
"src": "181:1:1"
},
{
"name": "y",
"nodeType": "YulIdentifier",
"src": "184:1:1"
}
],
"functionName": {
"name": "div",
"nodeType": "YulIdentifier",
"src": "177:3:1"
},
"nodeType": "YulFunctionCall",
"src": "177:9:1"
},
"variableNames": [
{
"name": "r",
"nodeType": "YulIdentifier",
"src": "172:1:1"
}
]
}
]
},
"name": "checked_div_t_uint256",
"nodeType": "YulFunctionDefinition",
"parameters": [
{
"name": "x",
"nodeType": "YulTypedName",
"src": "38:1:1",
"type": ""
},
{
"name": "y",
"nodeType": "YulTypedName",
"src": "41:1:1",
"type": ""
}
],
"returnVariables": [
{
"name": "r",
"nodeType": "YulTypedName",
"src": "47:1:1",
"type": ""
}
],
"src": "7:185:1"
},
{
"body": {
"nodeType": "YulBlock",
"src": "246:300:1",
"statements": [
{
"nodeType": "YulAssignment",
"src": "256:25:1",
"value": {
"arguments": [
{
"name": "x",
"nodeType": "YulIdentifier",
"src": "279:1:1"
}
],
"functionName": {
"name": "cleanup_t_uint256",
"nodeType": "YulIdentifier",
"src": "261:17:1"
},
"nodeType": "YulFunctionCall",
"src": "261:20:1"
},
"variableNames": [
{
"name": "x",
"nodeType": "YulIdentifier",
"src": "256:1:1"
}
]
},
{
"nodeType": "YulAssignment",
"src": "290:25:1",
"value": {
"arguments": [
{
"name": "y",
"nodeType": "YulIdentifier",
"src": "313:1:1"
}
],
"functionName": {
"name": "cleanup_t_uint256",
"nodeType": "YulIdentifier",
"src": "295:17:1"
},
"nodeType": "YulFunctionCall",
"src": "295:20:1"
},
"variableNames": [
{
"name": "y",
"nodeType": "YulIdentifier",
"src": "290:1:1"
}
]
},
{
"body": {
"nodeType": "YulBlock",
"src": "488:22:1",
"statements": [
{
"expression": {
"arguments": [],
"functionName": {
"name": "panic_error_0x11",
"nodeType": "YulIdentifier",
"src": "490:16:1"
},
"nodeType": "YulFunctionCall",
"src": "490:18:1"
},
"nodeType": "YulExpressionStatement",
"src": "490:18:1"
}
]
},
"condition": {
"arguments": [
{
"arguments": [
{
"arguments": [
{
"name": "x",
"nodeType": "YulIdentifier",
"src": "400:1:1"
}
],
"functionName": {
"name": "iszero",
"nodeType": "YulIdentifier",
"src": "393:6:1"
},
"nodeType": "YulFunctionCall",
"src": "393:9:1"
}
],
"functionName": {
"name": "iszero",
"nodeType": "YulIdentifier",
"src": "386:6:1"
},
"nodeType": "YulFunctionCall",
"src": "386:17:1"
},
{
"arguments": [
{
"name": "y",
"nodeType": "YulIdentifier",
"src": "408:1:1"
},
{
"arguments": [
{
"kind": "number",
"nodeType": "YulLiteral",
"src": "415:66:1",
"type": "",
"value": "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
},
{
"name": "x",
"nodeType": "YulIdentifier",
"src": "483:1:1"
}
],
"functionName": {
"name": "div",
"nodeType": "YulIdentifier",
"src": "411:3:1"
},
"nodeType": "YulFunctionCall",
"src": "411:74:1"
}
],
"functionName": {
"name": "gt",
"nodeType": "YulIdentifier",
"src": "405:2:1"
},
"nodeType": "YulFunctionCall",
"src": "405:81:1"
}
],
"functionName": {
"name": "and",
"nodeType": "YulIdentifier",
"src": "382:3:1"
},
"nodeType": "YulFunctionCall",
"src": "382:105:1"
},
"nodeType": "YulIf",
"src": "379:2:1"
},
{
"nodeType": "YulAssignment",
"src": "520:20:1",
"value": {
"arguments": [
{
"name": "x",
"nodeType": "YulIdentifier",
"src": "535:1:1"
},
{
"name": "y",
"nodeType": "YulIdentifier",
"src": "538:1:1"
}
],
"functionName": {
"name": "mul",
"nodeType": "YulIdentifier",
"src": "531:3:1"
},
"nodeType": "YulFunctionCall",
"src": "531:9:1"
},
"variableNames": [
{
"name": "product",
"nodeType": "YulIdentifier",
"src": "520:7:1"
}
]
}
]
},
"name": "checked_mul_t_uint256",
"nodeType": "YulFunctionDefinition",
"parameters": [
{
"name": "x",
"nodeType": "YulTypedName",
"src": "229:1:1",
"type": ""
},
{
"name": "y",
"nodeType": "YulTypedName",
"src": "232:1:1",
"type": ""
}
],
"returnVariables": [
{
"name": "product",
"nodeType": "YulTypedName",
"src": "238:7:1",
"type": ""
}
],
"src": "198:348:1"
},
{
"body": {
"nodeType": "YulBlock",
"src": "597:32:1",
"statements": [
{
"nodeType": "YulAssignment",
"src": "607:16:1",
"value": {
"name": "value",
"nodeType": "YulIdentifier",
"src": "618:5:1"
},
"variableNames": [
{
"name": "cleaned",
"nodeType": "YulIdentifier",
"src": "607:7:1"
}
]
}
]
},
"name": "cleanup_t_uint256",
"nodeType": "YulFunctionDefinition",
"parameters": [
{
"name": "value",
"nodeType": "YulTypedName",
"src": "579:5:1",
"type": ""
}
],
"returnVariables": [
{
"name": "cleaned",
"nodeType": "YulTypedName",
"src": "589:7:1",
"type": ""
}
],
"src": "552:77:1"
},
{
"body": {
"nodeType": "YulBlock",
"src": "663:152:1",
"statements": [
{
"expression": {
"arguments": [
{
"kind": "number",
"nodeType": "YulLiteral",
"src": "680:1:1",
"type": "",
"value": "0"
},
{
"kind": "number",
"nodeType": "YulLiteral",
"src": "683:77:1",
"type": "",
"value": "35408467139433450592217433187231851964531694900788300625387963629091585785856"
}
],
"functionName": {
"name": "mstore",
"nodeType": "YulIdentifier",
"src": "673:6:1"
},
"nodeType": "YulFunctionCall",
"src": "673:88:1"
},
"nodeType": "YulExpressionStatement",
"src": "673:88:1"
},
{
"expression": {
"arguments": [
{
"kind": "number",
"nodeType": "YulLiteral",
"src": "777:1:1",
"type": "",
"value": "4"
},
{
"kind": "number",
"nodeType": "YulLiteral",
"src": "780:4:1",
"type": "",
"value": "0x11"
}
],
"functionName": {
"name": "mstore",
"nodeType": "YulIdentifier",
"src": "770:6:1"
},
"nodeType": "YulFunctionCall",
"src": "770:15:1"
},
"nodeType": "YulExpressionStatement",
"src": "770:15:1"
},
{
"expression": {
"arguments": [
{
"kind": "number",
"nodeType": "YulLiteral",
"src": "801:1:1",
"type": "",
"value": "0"
},
{
"kind": "number",
"nodeType": "YulLiteral",
"src": "804:4:1",
"type": "",
"value": "0x24"
}
],
"functionName": {
"name": "revert",
"nodeType": "YulIdentifier",
"src": "794:6:1"
},
"nodeType": "YulFunctionCall",
"src": "794:15:1"
},
"nodeType": "YulExpressionStatement",
"src": "794:15:1"
}
]
},
"name": "panic_error_0x11",
"nodeType": "YulFunctionDefinition",
"src": "635:180:1"
},
{
"body": {
"nodeType": "YulBlock",
"src": "849:152:1",
"statements": [
{
"expression": {
"arguments": [
{
"kind": "number",
"nodeType": "YulLiteral",
"src": "866:1:1",
"type": "",
"value": "0"
},
{
"kind": "number",
"nodeType": "YulLiteral",
"src": "869:77:1",
"type": "",
"value": "35408467139433450592217433187231851964531694900788300625387963629091585785856"
}
],
"functionName": {
"name": "mstore",
"nodeType": "YulIdentifier",
"src": "859:6:1"
},
"nodeType": "YulFunctionCall",
"src": "859:88:1"
},
"nodeType": "YulExpressionStatement",
"src": "859:88:1"
},
{
"expression": {
"arguments": [
{
"kind": "number",
"nodeType": "YulLiteral",
"src": "963:1:1",
"type": "",
"value": "4"
},
{
"kind": "number",
"nodeType": "YulLiteral",
"src": "966:4:1",
"type": "",
"value": "0x12"
}
],
"functionName": {
"name": "mstore",
"nodeType": "YulIdentifier",
"src": "956:6:1"
},
"nodeType": "YulFunctionCall",
"src": "956:15:1"
},
"nodeType": "YulExpressionStatement",
"src": "956:15:1"
},
{
"expression": {
"arguments": [
{
"kind": "number",
"nodeType": "YulLiteral",
"src": "987:1:1",
"type": "",
"value": "0"
},
{
"kind": "number",
"nodeType": "YulLiteral",
"src": "990:4:1",
"type": "",
"value": "0x24"
}
],
"functionName": {
"name": "revert",
"nodeType": "YulIdentifier",
"src": "980:6:1"
},
"nodeType": "YulFunctionCall",
"src": "980:15:1"
},
"nodeType": "YulExpressionStatement",
"src": "980:15:1"
}
]
},
"name": "panic_error_0x12",
"nodeType": "YulFunctionDefinition",
"src": "821:180:1"
}
]
},
"contents": "{\n\n    function checked_div_t_uint256(x, y) -> r {\n        x := cleanup_t_uint256(x)\n        y := cleanup_t_uint256(y)\n        if iszero(y) { panic_error_0x12() }\n\n        r := div(x, y)\n    }\n\n    function checked_mul_t_uint256(x, y) -> product {\n        x := cleanup_t_uint256(x)\n        y := cleanup_t_uint256(y)\n\n        // overflow, if x != 0 and y > (maxValue / x)\n        if and(iszero(iszero(x)), gt(y, div(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, x))) { panic_error_0x11() }\n\n        product := mul(x, y)\n    }\n\n    function cleanup_t_uint256(value) -> cleaned {\n        cleaned := value\n    }\n\n    function panic_error_0x11() {\n        mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)\n        mstore(4, 0x11)\n        revert(0, 0x24)\n    }\n\n    function panic_error_0x12() {\n        mstore(0, 35408467139433450592217433187231851964531694900788300625387963629091585785856)\n        mstore(4, 0x12)\n        revert(0, 0x24)\n    }\n\n}\n",
"id": 1,
"language": "Yul",
"name": "#utility.yul"
}
],
"linkReferences": {},
"object": "608060405233600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555060023461005291906100a4565b60008190555034600054600261006891906100d5565b1461009f576040517fbe3e4c4200000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b610197565b60006100af8261012f565b91506100ba8361012f565b9250826100ca576100c9610168565b5b828204905092915050565b60006100e08261012f565b91506100eb8361012f565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff048311821515161561012457610123610139565b5b828202905092915050565b6000819050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b610be580620001a76000396000f3fe60806040526004361061007b5760003560e01c806373fac6f01161004e57806373fac6f014610118578063c19d93fb1461012f578063c7981b1b1461015a578063d6960697146101715761007b565b806308551a531461008057806335a063b4146100ab5780633fa4f245146100c25780637150d8ae146100ed575b600080fd5b34801561008c57600080fd5b5061009561017b565b6040516100a29190610a31565b60405180910390f35b3480156100b757600080fd5b506100c06101a1565b005b3480156100ce57600080fd5b506100d76103cb565b6040516100e49190610a67565b60405180910390f35b3480156100f957600080fd5b506101026103d1565b60405161010f9190610a31565b60405180910390f35b34801561012457600080fd5b5061012d6103f7565b005b34801561013b57600080fd5b50610144610622565b6040516101519190610a4c565b60405180910390f35b34801561016657600080fd5b5061016f610635565b005b61017961086d565b005b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610228576040517f85d1f72600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b6000806003811115610263577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b600260149054906101000a900460ff1660038111156102ab577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b146102e2576040517fbaf3f0f700000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b7f72c874aeff0b183a56e2b79c71b46e1aed4dee5e09862134b8821ba2fddbf8bf60405160405180910390a16003600260146101000a81548160ff0219169083600381111561035a577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b0217905550600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166108fc479081150290604051600060405180830381858888f193505050501580156103c7573d6000803e3d6000fd5b5050565b60005481565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161461047e576040517f86efbb5500000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60018060038111156104b9577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b600260149054906101000a900460ff166003811115610501577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b14610538576040517fbaf3f0f700000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b7fe89152acd703c9d8c7d28829d443260b411454d45394e7995815140c8cbcbcf760405160405180910390a160028060146101000a81548160ff021916908360038111156105af577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b0217905550600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166108fc6000549081150290604051600060405180830381858888f1935050505015801561061e573d6000803e3d6000fd5b5050565b600260149054906101000a900460ff1681565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146106bc576040517f85d1f72600000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60028060038111156106f7577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b600260149054906101000a900460ff16600381111561073f577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b14610776576040517fbaf3f0f700000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b7ffda69c32bcfdba840a167777906b173b607eb8b4d8853b97a80d26e613d858db60405160405180910390a16003600260146101000a81548160ff021916908360038111156107ee577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b0217905550600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166108fc600054600361083e9190610a82565b9081150290604051600060405180830381858888f19350505050158015610869573d6000803e3d6000fd5b5050565b60008060038111156108a8577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b600260149054906101000a900460ff1660038111156108f0577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b14610927576040517fbaf3f0f700000000000000000000000000000000000000000000000000000000815260040160405180910390fd5b60005460026109369190610a82565b34148061094257600080fd5b7fd5d55c8a68912e9a110618df8d5e2e83b8d83211c57a8ddd1203df92885dc88160405160405180910390a133600260006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506001600260146101000a81548160ff021916908360038111156109fb577f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b02179055505050565b610a0d81610adc565b82525050565b610a1c81610b2b565b82525050565b610a2b81610b21565b82525050565b6000602082019050610a466000830184610a04565b92915050565b6000602082019050610a616000830184610a13565b92915050565b6000602082019050610a7c6000830184610a22565b92915050565b6000610a8d82610b21565b9150610a9883610b21565b9250817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0483118215151615610ad157610ad0610b3d565b5b828202905092915050565b6000610ae782610b01565b9050919050565b6000819050610afc82610b9b565b919050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000819050919050565b6000610b3682610aee565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602160045260246000fd5b60048110610bac57610bab610b6c565b5b5056fea2646970667358221220abec5d1083acf78017eb4db3ecdbd3c0f263111133c6896d1c45ed74bf0ee16f64736f6c63430008040033",
"opcodes": "PUSH1 0x80 PUSH1 0x40 MSTORE CALLER PUSH1 0x1 PUSH1 0x0 PUSH2 0x100 EXP DUP2 SLOAD DUP2 PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF MUL NOT AND SWAP1 DUP4 PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND MUL OR SWAP1 SSTORE POP PUSH1 0x2 CALLVALUE PUSH2 0x52 SWAP2 SWAP1 PUSH2 0xA4 JUMP JUMPDEST PUSH1 0x0 DUP2 SWAP1 SSTORE POP CALLVALUE PUSH1 0x0 SLOAD PUSH1 0x2 PUSH2 0x68 SWAP2 SWAP1 PUSH2 0xD5 JUMP JUMPDEST EQ PUSH2 0x9F JUMPI PUSH1 0x40 MLOAD PUSH32 0xBE3E4C4200000000000000000000000000000000000000000000000000000000 DUP2 MSTORE PUSH1 0x4 ADD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 REVERT JUMPDEST PUSH2 0x197 JUMP JUMPDEST PUSH1 0x0 PUSH2 0xAF DUP3 PUSH2 0x12F JUMP JUMPDEST SWAP2 POP PUSH2 0xBA DUP4 PUSH2 0x12F JUMP JUMPDEST SWAP3 POP DUP3 PUSH2 0xCA JUMPI PUSH2 0xC9 PUSH2 0x168 JUMP JUMPDEST JUMPDEST DUP3 DUP3 DIV SWAP1 POP SWAP3 SWAP2 POP POP JUMP JUMPDEST PUSH1 0x0 PUSH2 0xE0 DUP3 PUSH2 0x12F JUMP JUMPDEST SWAP2 POP PUSH2 0xEB DUP4 PUSH2 0x12F JUMP JUMPDEST SWAP3 POP DUP2 PUSH32 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF DIV DUP4 GT DUP3 ISZERO ISZERO AND ISZERO PUSH2 0x124 JUMPI PUSH2 0x123 PUSH2 0x139 JUMP JUMPDEST JUMPDEST DUP3 DUP3 MUL SWAP1 POP SWAP3 SWAP2 POP POP JUMP JUMPDEST PUSH1 0x0 DUP2 SWAP1 POP SWAP2 SWAP1 POP JUMP JUMPDEST PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x11 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x12 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST PUSH2 0xBE5 DUP1 PUSH3 0x1A7 PUSH1 0x0 CODECOPY PUSH1 0x0 RETURN INVALID PUSH1 0x80 PUSH1 0x40 MSTORE PUSH1 0x4 CALLDATASIZE LT PUSH2 0x7B JUMPI PUSH1 0x0 CALLDATALOAD PUSH1 0xE0 SHR DUP1 PUSH4 0x73FAC6F0 GT PUSH2 0x4E JUMPI DUP1 PUSH4 0x73FAC6F0 EQ PUSH2 0x118 JUMPI DUP1 PUSH4 0xC19D93FB EQ PUSH2 0x12F JUMPI DUP1 PUSH4 0xC7981B1B EQ PUSH2 0x15A JUMPI DUP1 PUSH4 0xD6960697 EQ PUSH2 0x171 JUMPI PUSH2 0x7B JUMP JUMPDEST DUP1 PUSH4 0x8551A53 EQ PUSH2 0x80 JUMPI DUP1 PUSH4 0x35A063B4 EQ PUSH2 0xAB JUMPI DUP1 PUSH4 0x3FA4F245 EQ PUSH2 0xC2 JUMPI DUP1 PUSH4 0x7150D8AE EQ PUSH2 0xED JUMPI JUMPDEST PUSH1 0x0 DUP1 REVERT JUMPDEST CALLVALUE DUP1 ISZERO PUSH2 0x8C JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST POP PUSH2 0x95 PUSH2 0x17B JUMP JUMPDEST PUSH1 0x40 MLOAD PUSH2 0xA2 SWAP2 SWAP1 PUSH2 0xA31 JUMP JUMPDEST PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 RETURN JUMPDEST CALLVALUE DUP1 ISZERO PUSH2 0xB7 JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST POP PUSH2 0xC0 PUSH2 0x1A1 JUMP JUMPDEST STOP JUMPDEST CALLVALUE DUP1 ISZERO PUSH2 0xCE JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST POP PUSH2 0xD7 PUSH2 0x3CB JUMP JUMPDEST PUSH1 0x40 MLOAD PUSH2 0xE4 SWAP2 SWAP1 PUSH2 0xA67 JUMP JUMPDEST PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 RETURN JUMPDEST CALLVALUE DUP1 ISZERO PUSH2 0xF9 JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST POP PUSH2 0x102 PUSH2 0x3D1 JUMP JUMPDEST PUSH1 0x40 MLOAD PUSH2 0x10F SWAP2 SWAP1 PUSH2 0xA31 JUMP JUMPDEST PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 RETURN JUMPDEST CALLVALUE DUP1 ISZERO PUSH2 0x124 JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST POP PUSH2 0x12D PUSH2 0x3F7 JUMP JUMPDEST STOP JUMPDEST CALLVALUE DUP1 ISZERO PUSH2 0x13B JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST POP PUSH2 0x144 PUSH2 0x622 JUMP JUMPDEST PUSH1 0x40 MLOAD PUSH2 0x151 SWAP2 SWAP1 PUSH2 0xA4C JUMP JUMPDEST PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 RETURN JUMPDEST CALLVALUE DUP1 ISZERO PUSH2 0x166 JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST POP PUSH2 0x16F PUSH2 0x635 JUMP JUMPDEST STOP JUMPDEST PUSH2 0x179 PUSH2 0x86D JUMP JUMPDEST STOP JUMPDEST PUSH1 0x1 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND DUP2 JUMP JUMPDEST PUSH1 0x1 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND CALLER PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND EQ PUSH2 0x228 JUMPI PUSH1 0x40 MLOAD PUSH32 0x85D1F72600000000000000000000000000000000000000000000000000000000 DUP2 MSTORE PUSH1 0x4 ADD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 REVERT JUMPDEST PUSH1 0x0 DUP1 PUSH1 0x3 DUP2 GT ISZERO PUSH2 0x263 JUMPI PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x21 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST PUSH1 0x2 PUSH1 0x14 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH1 0xFF AND PUSH1 0x3 DUP2 GT ISZERO PUSH2 0x2AB JUMPI PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x21 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST EQ PUSH2 0x2E2 JUMPI PUSH1 0x40 MLOAD PUSH32 0xBAF3F0F700000000000000000000000000000000000000000000000000000000 DUP2 MSTORE PUSH1 0x4 ADD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 REVERT JUMPDEST PUSH32 0x72C874AEFF0B183A56E2B79C71B46E1AED4DEE5E09862134B8821BA2FDDBF8BF PUSH1 0x40 MLOAD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 LOG1 PUSH1 0x3 PUSH1 0x2 PUSH1 0x14 PUSH2 0x100 EXP DUP2 SLOAD DUP2 PUSH1 0xFF MUL NOT AND SWAP1 DUP4 PUSH1 0x3 DUP2 GT ISZERO PUSH2 0x35A JUMPI PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x21 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST MUL OR SWAP1 SSTORE POP PUSH1 0x1 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH2 0x8FC SELFBALANCE SWAP1 DUP2 ISZERO MUL SWAP1 PUSH1 0x40 MLOAD PUSH1 0x0 PUSH1 0x40 MLOAD DUP1 DUP4 SUB DUP2 DUP6 DUP9 DUP9 CALL SWAP4 POP POP POP POP ISZERO DUP1 ISZERO PUSH2 0x3C7 JUMPI RETURNDATASIZE PUSH1 0x0 DUP1 RETURNDATACOPY RETURNDATASIZE PUSH1 0x0 REVERT JUMPDEST POP POP JUMP JUMPDEST PUSH1 0x0 SLOAD DUP2 JUMP JUMPDEST PUSH1 0x2 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND DUP2 JUMP JUMPDEST PUSH1 0x2 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND CALLER PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND EQ PUSH2 0x47E JUMPI PUSH1 0x40 MLOAD PUSH32 0x86EFBB5500000000000000000000000000000000000000000000000000000000 DUP2 MSTORE PUSH1 0x4 ADD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 REVERT JUMPDEST PUSH1 0x1 DUP1 PUSH1 0x3 DUP2 GT ISZERO PUSH2 0x4B9 JUMPI PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x21 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST PUSH1 0x2 PUSH1 0x14 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH1 0xFF AND PUSH1 0x3 DUP2 GT ISZERO PUSH2 0x501 JUMPI PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x21 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST EQ PUSH2 0x538 JUMPI PUSH1 0x40 MLOAD PUSH32 0xBAF3F0F700000000000000000000000000000000000000000000000000000000 DUP2 MSTORE PUSH1 0x4 ADD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 REVERT JUMPDEST PUSH32 0xE89152ACD703C9D8C7D28829D443260B411454D45394E7995815140C8CBCBCF7 PUSH1 0x40 MLOAD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 LOG1 PUSH1 0x2 DUP1 PUSH1 0x14 PUSH2 0x100 EXP DUP2 SLOAD DUP2 PUSH1 0xFF MUL NOT AND SWAP1 DUP4 PUSH1 0x3 DUP2 GT ISZERO PUSH2 0x5AF JUMPI PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x21 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST MUL OR SWAP1 SSTORE POP PUSH1 0x2 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH2 0x8FC PUSH1 0x0 SLOAD SWAP1 DUP2 ISZERO MUL SWAP1 PUSH1 0x40 MLOAD PUSH1 0x0 PUSH1 0x40 MLOAD DUP1 DUP4 SUB DUP2 DUP6 DUP9 DUP9 CALL SWAP4 POP POP POP POP ISZERO DUP1 ISZERO PUSH2 0x61E JUMPI RETURNDATASIZE PUSH1 0x0 DUP1 RETURNDATACOPY RETURNDATASIZE PUSH1 0x0 REVERT JUMPDEST POP POP JUMP JUMPDEST PUSH1 0x2 PUSH1 0x14 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH1 0xFF AND DUP2 JUMP JUMPDEST PUSH1 0x1 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND CALLER PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND EQ PUSH2 0x6BC JUMPI PUSH1 0x40 MLOAD PUSH32 0x85D1F72600000000000000000000000000000000000000000000000000000000 DUP2 MSTORE PUSH1 0x4 ADD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 REVERT JUMPDEST PUSH1 0x2 DUP1 PUSH1 0x3 DUP2 GT ISZERO PUSH2 0x6F7 JUMPI PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x21 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST PUSH1 0x2 PUSH1 0x14 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH1 0xFF AND PUSH1 0x3 DUP2 GT ISZERO PUSH2 0x73F JUMPI PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x21 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST EQ PUSH2 0x776 JUMPI PUSH1 0x40 MLOAD PUSH32 0xBAF3F0F700000000000000000000000000000000000000000000000000000000 DUP2 MSTORE PUSH1 0x4 ADD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 REVERT JUMPDEST PUSH32 0xFDA69C32BCFDBA840A167777906B173B607EB8B4D8853B97A80D26E613D858DB PUSH1 0x40 MLOAD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 LOG1 PUSH1 0x3 PUSH1 0x2 PUSH1 0x14 PUSH2 0x100 EXP DUP2 SLOAD DUP2 PUSH1 0xFF MUL NOT AND SWAP1 DUP4 PUSH1 0x3 DUP2 GT ISZERO PUSH2 0x7EE JUMPI PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x21 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST MUL OR SWAP1 SSTORE POP PUSH1 0x1 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH2 0x8FC PUSH1 0x0 SLOAD PUSH1 0x3 PUSH2 0x83E SWAP2 SWAP1 PUSH2 0xA82 JUMP JUMPDEST SWAP1 DUP2 ISZERO MUL SWAP1 PUSH1 0x40 MLOAD PUSH1 0x0 PUSH1 0x40 MLOAD DUP1 DUP4 SUB DUP2 DUP6 DUP9 DUP9 CALL SWAP4 POP POP POP POP ISZERO DUP1 ISZERO PUSH2 0x869 JUMPI RETURNDATASIZE PUSH1 0x0 DUP1 RETURNDATACOPY RETURNDATASIZE PUSH1 0x0 REVERT JUMPDEST POP POP JUMP JUMPDEST PUSH1 0x0 DUP1 PUSH1 0x3 DUP2 GT ISZERO PUSH2 0x8A8 JUMPI PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x21 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST PUSH1 0x2 PUSH1 0x14 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH1 0xFF AND PUSH1 0x3 DUP2 GT ISZERO PUSH2 0x8F0 JUMPI PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x21 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST EQ PUSH2 0x927 JUMPI PUSH1 0x40 MLOAD PUSH32 0xBAF3F0F700000000000000000000000000000000000000000000000000000000 DUP2 MSTORE PUSH1 0x4 ADD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 REVERT JUMPDEST PUSH1 0x0 SLOAD PUSH1 0x2 PUSH2 0x936 SWAP2 SWAP1 PUSH2 0xA82 JUMP JUMPDEST CALLVALUE EQ DUP1 PUSH2 0x942 JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST PUSH32 0xD5D55C8A68912E9A110618DF8D5E2E83B8D83211C57A8DDD1203DF92885DC881 PUSH1 0x40 MLOAD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 LOG1 CALLER PUSH1 0x2 PUSH1 0x0 PUSH2 0x100 EXP DUP2 SLOAD DUP2 PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF MUL NOT AND SWAP1 DUP4 PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND MUL OR SWAP1 SSTORE POP PUSH1 0x1 PUSH1 0x2 PUSH1 0x14 PUSH2 0x100 EXP DUP2 SLOAD DUP2 PUSH1 0xFF MUL NOT AND SWAP1 DUP4 PUSH1 0x3 DUP2 GT ISZERO PUSH2 0x9FB JUMPI PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x21 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST MUL OR SWAP1 SSTORE POP POP POP JUMP JUMPDEST PUSH2 0xA0D DUP2 PUSH2 0xADC JUMP JUMPDEST DUP3 MSTORE POP POP JUMP JUMPDEST PUSH2 0xA1C DUP2 PUSH2 0xB2B JUMP JUMPDEST DUP3 MSTORE POP POP JUMP JUMPDEST PUSH2 0xA2B DUP2 PUSH2 0xB21 JUMP JUMPDEST DUP3 MSTORE POP POP JUMP JUMPDEST PUSH1 0x0 PUSH1 0x20 DUP3 ADD SWAP1 POP PUSH2 0xA46 PUSH1 0x0 DUP4 ADD DUP5 PUSH2 0xA04 JUMP JUMPDEST SWAP3 SWAP2 POP POP JUMP JUMPDEST PUSH1 0x0 PUSH1 0x20 DUP3 ADD SWAP1 POP PUSH2 0xA61 PUSH1 0x0 DUP4 ADD DUP5 PUSH2 0xA13 JUMP JUMPDEST SWAP3 SWAP2 POP POP JUMP JUMPDEST PUSH1 0x0 PUSH1 0x20 DUP3 ADD SWAP1 POP PUSH2 0xA7C PUSH1 0x0 DUP4 ADD DUP5 PUSH2 0xA22 JUMP JUMPDEST SWAP3 SWAP2 POP POP JUMP JUMPDEST PUSH1 0x0 PUSH2 0xA8D DUP3 PUSH2 0xB21 JUMP JUMPDEST SWAP2 POP PUSH2 0xA98 DUP4 PUSH2 0xB21 JUMP JUMPDEST SWAP3 POP DUP2 PUSH32 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF DIV DUP4 GT DUP3 ISZERO ISZERO AND ISZERO PUSH2 0xAD1 JUMPI PUSH2 0xAD0 PUSH2 0xB3D JUMP JUMPDEST JUMPDEST DUP3 DUP3 MUL SWAP1 POP SWAP3 SWAP2 POP POP JUMP JUMPDEST PUSH1 0x0 PUSH2 0xAE7 DUP3 PUSH2 0xB01 JUMP JUMPDEST SWAP1 POP SWAP2 SWAP1 POP JUMP JUMPDEST PUSH1 0x0 DUP2 SWAP1 POP PUSH2 0xAFC DUP3 PUSH2 0xB9B JUMP JUMPDEST SWAP2 SWAP1 POP JUMP JUMPDEST PUSH1 0x0 PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF DUP3 AND SWAP1 POP SWAP2 SWAP1 POP JUMP JUMPDEST PUSH1 0x0 DUP2 SWAP1 POP SWAP2 SWAP1 POP JUMP JUMPDEST PUSH1 0x0 PUSH2 0xB36 DUP3 PUSH2 0xAEE JUMP JUMPDEST SWAP1 POP SWAP2 SWAP1 POP JUMP JUMPDEST PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x11 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST PUSH32 0x4E487B7100000000000000000000000000000000000000000000000000000000 PUSH1 0x0 MSTORE PUSH1 0x21 PUSH1 0x4 MSTORE PUSH1 0x24 PUSH1 0x0 REVERT JUMPDEST PUSH1 0x4 DUP2 LT PUSH2 0xBAC JUMPI PUSH2 0xBAB PUSH2 0xB6C JUMP JUMPDEST JUMPDEST POP JUMP INVALID LOG2 PUSH5 0x6970667358 0x22 SLT KECCAK256 0xAB 0xEC 0x5D LT DUP4 0xAC 0xF7 DUP1 OR 0xEB 0x4D 0xB3 0xEC 0xDB 0xD3 0xC0 CALLCODE PUSH4 0x111133C6 DUP10 PUSH14 0x1C45ED74BF0EE16F64736F6C6343 STOP ADDMOD DIV STOP CALLER ",
"sourceMap": "60:3300:0:-:0;;;1390:10;1373:6;;:28;;;;;;;;;;;;;;;;;;1431:1;1419:9;:13;;;;:::i;:::-;1411:5;:21;;;;1461:9;1451:5;;1447:1;:9;;;;:::i;:::-;1446:24;1442:63;;1491:14;;;;;;;;;;;;;;1442:63;60:3300;;7:185:1;47:1;64:20;82:1;64:20;:::i;:::-;59:25;;98:20;116:1;98:20;:::i;:::-;93:25;;137:1;127:2;;142:18;;:::i;:::-;127:2;184:1;181;177:9;172:14;;49:143;;;;:::o;198:348::-;238:7;261:20;279:1;261:20;:::i;:::-;256:25;;295:20;313:1;295:20;:::i;:::-;290:25;;483:1;415:66;411:74;408:1;405:81;400:1;393:9;386:17;382:105;379:2;;;490:18;;:::i;:::-;379:2;538:1;535;531:9;520:20;;246:300;;;;:::o;552:77::-;589:7;618:5;607:16;;597:32;;;:::o;635:180::-;683:77;680:1;673:88;780:4;777:1;770:15;804:4;801:1;794:15;821:180;869:77;866:1;859:88;966:4;963:1;956:15;990:4;987:1;980:15;60:3300:0;;;;;;;"
}
"""

// MARK: - someABI

let someABI = """
[
    {
        "inputs": [],
        "stateMutability": "payable",
        "type": "constructor"
    },
    {
        "anonymous": false,
        "inputs": [],
        "name": "Aborted",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [],
        "name": "ItemReceived",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [],
        "name": "PurchaseConfirmed",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [],
        "name": "SellerRefunded",
        "type": "event"
    },
    {
        "inputs": [],
        "name": "abort",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "buyer",
        "outputs": [
            {
                "internalType": "address payable",
                "name": "",
                "type": "address"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "confirmPurchase",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "confirmReceived",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "refundSeller",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "seller",
        "outputs": [
            {
                "internalType": "address payable",
                "name": "",
                "type": "address"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "state",
        "outputs": [
            {
                "internalType": "enum Purchase.State",
                "name": "",
                "type": "uint8"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "value",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
]
"""

let purchaseBytecode2 = """
608060405233600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506002348161004f57fe5b0460008190555034600054600202146100d0576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260158152602001807f56616c75652068617320746f206265206576656e2e000000000000000000000081525060200191505060405180910390fd5b61083b806100df6000396000f3fe6080604052600436106100705760003560e01c80637150d8ae1161004e5780637150d8ae1461010e57806373fac6f014610165578063c19d93fb1461017c578063d6960697146101b557610070565b806308551a531461007557806335a063b4146100cc5780633fa4f245146100e3575b600080fd5b34801561008157600080fd5b5061008a6101bf565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b3480156100d857600080fd5b506100e16101e5565b005b3480156100ef57600080fd5b506100f86103ff565b6040518082815260200191505060405180910390f35b34801561011a57600080fd5b50610123610405565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b34801561017157600080fd5b5061017a61042b565b005b34801561018857600080fd5b506101916106b0565b604051808260028111156101a157fe5b60ff16815260200191505060405180910390f35b6101bd6106c3565b005b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146102a8576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252601a8152602001807f4f6e6c792073656c6c65722063616e2063616c6c20746869732e00000000000081525060200191505060405180910390fd5b60008060028111156102b657fe5b600260149054906101000a900460ff1660028111156102d157fe5b14610344576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252600e8152602001807f496e76616c69642073746174652e00000000000000000000000000000000000081525060200191505060405180910390fd5b7f72c874aeff0b183a56e2b79c71b46e1aed4dee5e09862134b8821ba2fddbf8bf60405160405180910390a160028060146101000a81548160ff0219169083600281111561038e57fe5b0217905550600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166108fc479081150290604051600060405180830381858888f193505050501580156103fb573d6000803e3d6000fd5b5050565b60005481565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146104ee576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260198152602001807f4f6e6c792062757965722063616e2063616c6c20746869732e0000000000000081525060200191505060405180910390fd5b60018060028111156104fc57fe5b600260149054906101000a900460ff16600281111561051757fe5b1461058a576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252600e8152602001807f496e76616c69642073746174652e00000000000000000000000000000000000081525060200191505060405180910390fd5b7fe89152acd703c9d8c7d28829d443260b411454d45394e7995815140c8cbcbcf760405160405180910390a160028060146101000a81548160ff021916908360028111156105d457fe5b0217905550600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166108fc6000549081150290604051600060405180830381858888f19350505050158015610643573d6000803e3d6000fd5b50600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166108fc479081150290604051600060405180830381858888f193505050501580156106ac573d6000803e3d6000fd5b5050565b600260149054906101000a900460ff1681565b60008060028111156106d157fe5b600260149054906101000a900460ff1660028111156106ec57fe5b1461075f576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252600e8152602001807f496e76616c69642073746174652e00000000000000000000000000000000000081525060200191505060405180910390fd5b60005460020234148061077157600080fd5b7fd5d55c8a68912e9a110618df8d5e2e83b8d83211c57a8ddd1203df92885dc88160405160405180910390a133600260006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506001600260146101000a81548160ff021916908360028111156107fd57fe5b0217905550505056fea265627a7a72315820a6d28fbba7c2bbf2b8cc9b20c3b92e35fec130e8d7b29afd62261304757cb6ba64736f6c63430005110032
"""

let fullByteCode = """
{
"linkReferences": {},
"object": "608060405233600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506002348161004f57fe5b0460008190555034600054600202146100d0576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260158152602001807f56616c75652068617320746f206265206576656e2e000000000000000000000081525060200191505060405180910390fd5b61083b806100df6000396000f3fe6080604052600436106100705760003560e01c80637150d8ae1161004e5780637150d8ae1461010e57806373fac6f014610165578063c19d93fb1461017c578063d6960697146101b557610070565b806308551a531461007557806335a063b4146100cc5780633fa4f245146100e3575b600080fd5b34801561008157600080fd5b5061008a6101bf565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b3480156100d857600080fd5b506100e16101e5565b005b3480156100ef57600080fd5b506100f86103ff565b6040518082815260200191505060405180910390f35b34801561011a57600080fd5b50610123610405565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b34801561017157600080fd5b5061017a61042b565b005b34801561018857600080fd5b506101916106b0565b604051808260028111156101a157fe5b60ff16815260200191505060405180910390f35b6101bd6106c3565b005b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146102a8576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252601a8152602001807f4f6e6c792073656c6c65722063616e2063616c6c20746869732e00000000000081525060200191505060405180910390fd5b60008060028111156102b657fe5b600260149054906101000a900460ff1660028111156102d157fe5b14610344576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252600e8152602001807f496e76616c69642073746174652e00000000000000000000000000000000000081525060200191505060405180910390fd5b7f72c874aeff0b183a56e2b79c71b46e1aed4dee5e09862134b8821ba2fddbf8bf60405160405180910390a160028060146101000a81548160ff0219169083600281111561038e57fe5b0217905550600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166108fc479081150290604051600060405180830381858888f193505050501580156103fb573d6000803e3d6000fd5b5050565b60005481565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16146104ee576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260198152602001807f4f6e6c792062757965722063616e2063616c6c20746869732e0000000000000081525060200191505060405180910390fd5b60018060028111156104fc57fe5b600260149054906101000a900460ff16600281111561051757fe5b1461058a576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252600e8152602001807f496e76616c69642073746174652e00000000000000000000000000000000000081525060200191505060405180910390fd5b7fe89152acd703c9d8c7d28829d443260b411454d45394e7995815140c8cbcbcf760405160405180910390a160028060146101000a81548160ff021916908360028111156105d457fe5b0217905550600260009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166108fc6000549081150290604051600060405180830381858888f19350505050158015610643573d6000803e3d6000fd5b50600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff166108fc479081150290604051600060405180830381858888f193505050501580156106ac573d6000803e3d6000fd5b5050565b600260149054906101000a900460ff1681565b60008060028111156106d157fe5b600260149054906101000a900460ff1660028111156106ec57fe5b1461075f576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040180806020018281038252600e8152602001807f496e76616c69642073746174652e00000000000000000000000000000000000081525060200191505060405180910390fd5b60005460020234148061077157600080fd5b7fd5d55c8a68912e9a110618df8d5e2e83b8d83211c57a8ddd1203df92885dc88160405160405180910390a133600260006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055506001600260146101000a81548160ff021916908360028111156107fd57fe5b0217905550505056fea265627a7a72315820a6d28fbba7c2bbf2b8cc9b20c3b92e35fec130e8d7b29afd62261304757cb6ba64736f6c63430005110032",
"opcodes": "PUSH1 0x80 PUSH1 0x40 MSTORE CALLER PUSH1 0x1 PUSH1 0x0 PUSH2 0x100 EXP DUP2 SLOAD DUP2 PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF MUL NOT AND SWAP1 DUP4 PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND MUL OR SWAP1 SSTORE POP PUSH1 0x2 CALLVALUE DUP2 PUSH2 0x4F JUMPI INVALID JUMPDEST DIV PUSH1 0x0 DUP2 SWAP1 SSTORE POP CALLVALUE PUSH1 0x0 SLOAD PUSH1 0x2 MUL EQ PUSH2 0xD0 JUMPI PUSH1 0x40 MLOAD PUSH32 0x8C379A000000000000000000000000000000000000000000000000000000000 DUP2 MSTORE PUSH1 0x4 ADD DUP1 DUP1 PUSH1 0x20 ADD DUP3 DUP2 SUB DUP3 MSTORE PUSH1 0x15 DUP2 MSTORE PUSH1 0x20 ADD DUP1 PUSH32 0x56616C75652068617320746F206265206576656E2E0000000000000000000000 DUP2 MSTORE POP PUSH1 0x20 ADD SWAP2 POP POP PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 REVERT JUMPDEST PUSH2 0x83B DUP1 PUSH2 0xDF PUSH1 0x0 CODECOPY PUSH1 0x0 RETURN INVALID PUSH1 0x80 PUSH1 0x40 MSTORE PUSH1 0x4 CALLDATASIZE LT PUSH2 0x70 JUMPI PUSH1 0x0 CALLDATALOAD PUSH1 0xE0 SHR DUP1 PUSH4 0x7150D8AE GT PUSH2 0x4E JUMPI DUP1 PUSH4 0x7150D8AE EQ PUSH2 0x10E JUMPI DUP1 PUSH4 0x73FAC6F0 EQ PUSH2 0x165 JUMPI DUP1 PUSH4 0xC19D93FB EQ PUSH2 0x17C JUMPI DUP1 PUSH4 0xD6960697 EQ PUSH2 0x1B5 JUMPI PUSH2 0x70 JUMP JUMPDEST DUP1 PUSH4 0x8551A53 EQ PUSH2 0x75 JUMPI DUP1 PUSH4 0x35A063B4 EQ PUSH2 0xCC JUMPI DUP1 PUSH4 0x3FA4F245 EQ PUSH2 0xE3 JUMPI JUMPDEST PUSH1 0x0 DUP1 REVERT JUMPDEST CALLVALUE DUP1 ISZERO PUSH2 0x81 JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST POP PUSH2 0x8A PUSH2 0x1BF JUMP JUMPDEST PUSH1 0x40 MLOAD DUP1 DUP3 PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND DUP2 MSTORE PUSH1 0x20 ADD SWAP2 POP POP PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 RETURN JUMPDEST CALLVALUE DUP1 ISZERO PUSH2 0xD8 JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST POP PUSH2 0xE1 PUSH2 0x1E5 JUMP JUMPDEST STOP JUMPDEST CALLVALUE DUP1 ISZERO PUSH2 0xEF JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST POP PUSH2 0xF8 PUSH2 0x3FF JUMP JUMPDEST PUSH1 0x40 MLOAD DUP1 DUP3 DUP2 MSTORE PUSH1 0x20 ADD SWAP2 POP POP PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 RETURN JUMPDEST CALLVALUE DUP1 ISZERO PUSH2 0x11A JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST POP PUSH2 0x123 PUSH2 0x405 JUMP JUMPDEST PUSH1 0x40 MLOAD DUP1 DUP3 PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND DUP2 MSTORE PUSH1 0x20 ADD SWAP2 POP POP PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 RETURN JUMPDEST CALLVALUE DUP1 ISZERO PUSH2 0x171 JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST POP PUSH2 0x17A PUSH2 0x42B JUMP JUMPDEST STOP JUMPDEST CALLVALUE DUP1 ISZERO PUSH2 0x188 JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST POP PUSH2 0x191 PUSH2 0x6B0 JUMP JUMPDEST PUSH1 0x40 MLOAD DUP1 DUP3 PUSH1 0x2 DUP2 GT ISZERO PUSH2 0x1A1 JUMPI INVALID JUMPDEST PUSH1 0xFF AND DUP2 MSTORE PUSH1 0x20 ADD SWAP2 POP POP PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 RETURN JUMPDEST PUSH2 0x1BD PUSH2 0x6C3 JUMP JUMPDEST STOP JUMPDEST PUSH1 0x1 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND DUP2 JUMP JUMPDEST PUSH1 0x1 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND CALLER PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND EQ PUSH2 0x2A8 JUMPI PUSH1 0x40 MLOAD PUSH32 0x8C379A000000000000000000000000000000000000000000000000000000000 DUP2 MSTORE PUSH1 0x4 ADD DUP1 DUP1 PUSH1 0x20 ADD DUP3 DUP2 SUB DUP3 MSTORE PUSH1 0x1A DUP2 MSTORE PUSH1 0x20 ADD DUP1 PUSH32 0x4F6E6C792073656C6C65722063616E2063616C6C20746869732E000000000000 DUP2 MSTORE POP PUSH1 0x20 ADD SWAP2 POP POP PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 REVERT JUMPDEST PUSH1 0x0 DUP1 PUSH1 0x2 DUP2 GT ISZERO PUSH2 0x2B6 JUMPI INVALID JUMPDEST PUSH1 0x2 PUSH1 0x14 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH1 0xFF AND PUSH1 0x2 DUP2 GT ISZERO PUSH2 0x2D1 JUMPI INVALID JUMPDEST EQ PUSH2 0x344 JUMPI PUSH1 0x40 MLOAD PUSH32 0x8C379A000000000000000000000000000000000000000000000000000000000 DUP2 MSTORE PUSH1 0x4 ADD DUP1 DUP1 PUSH1 0x20 ADD DUP3 DUP2 SUB DUP3 MSTORE PUSH1 0xE DUP2 MSTORE PUSH1 0x20 ADD DUP1 PUSH32 0x496E76616C69642073746174652E000000000000000000000000000000000000 DUP2 MSTORE POP PUSH1 0x20 ADD SWAP2 POP POP PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 REVERT JUMPDEST PUSH32 0x72C874AEFF0B183A56E2B79C71B46E1AED4DEE5E09862134B8821BA2FDDBF8BF PUSH1 0x40 MLOAD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 LOG1 PUSH1 0x2 DUP1 PUSH1 0x14 PUSH2 0x100 EXP DUP2 SLOAD DUP2 PUSH1 0xFF MUL NOT AND SWAP1 DUP4 PUSH1 0x2 DUP2 GT ISZERO PUSH2 0x38E JUMPI INVALID JUMPDEST MUL OR SWAP1 SSTORE POP PUSH1 0x1 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH2 0x8FC SELFBALANCE SWAP1 DUP2 ISZERO MUL SWAP1 PUSH1 0x40 MLOAD PUSH1 0x0 PUSH1 0x40 MLOAD DUP1 DUP4 SUB DUP2 DUP6 DUP9 DUP9 CALL SWAP4 POP POP POP POP ISZERO DUP1 ISZERO PUSH2 0x3FB JUMPI RETURNDATASIZE PUSH1 0x0 DUP1 RETURNDATACOPY RETURNDATASIZE PUSH1 0x0 REVERT JUMPDEST POP POP JUMP JUMPDEST PUSH1 0x0 SLOAD DUP2 JUMP JUMPDEST PUSH1 0x2 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND DUP2 JUMP JUMPDEST PUSH1 0x2 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND CALLER PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND EQ PUSH2 0x4EE JUMPI PUSH1 0x40 MLOAD PUSH32 0x8C379A000000000000000000000000000000000000000000000000000000000 DUP2 MSTORE PUSH1 0x4 ADD DUP1 DUP1 PUSH1 0x20 ADD DUP3 DUP2 SUB DUP3 MSTORE PUSH1 0x19 DUP2 MSTORE PUSH1 0x20 ADD DUP1 PUSH32 0x4F6E6C792062757965722063616E2063616C6C20746869732E00000000000000 DUP2 MSTORE POP PUSH1 0x20 ADD SWAP2 POP POP PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 REVERT JUMPDEST PUSH1 0x1 DUP1 PUSH1 0x2 DUP2 GT ISZERO PUSH2 0x4FC JUMPI INVALID JUMPDEST PUSH1 0x2 PUSH1 0x14 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH1 0xFF AND PUSH1 0x2 DUP2 GT ISZERO PUSH2 0x517 JUMPI INVALID JUMPDEST EQ PUSH2 0x58A JUMPI PUSH1 0x40 MLOAD PUSH32 0x8C379A000000000000000000000000000000000000000000000000000000000 DUP2 MSTORE PUSH1 0x4 ADD DUP1 DUP1 PUSH1 0x20 ADD DUP3 DUP2 SUB DUP3 MSTORE PUSH1 0xE DUP2 MSTORE PUSH1 0x20 ADD DUP1 PUSH32 0x496E76616C69642073746174652E000000000000000000000000000000000000 DUP2 MSTORE POP PUSH1 0x20 ADD SWAP2 POP POP PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 REVERT JUMPDEST PUSH32 0xE89152ACD703C9D8C7D28829D443260B411454D45394E7995815140C8CBCBCF7 PUSH1 0x40 MLOAD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 LOG1 PUSH1 0x2 DUP1 PUSH1 0x14 PUSH2 0x100 EXP DUP2 SLOAD DUP2 PUSH1 0xFF MUL NOT AND SWAP1 DUP4 PUSH1 0x2 DUP2 GT ISZERO PUSH2 0x5D4 JUMPI INVALID JUMPDEST MUL OR SWAP1 SSTORE POP PUSH1 0x2 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH2 0x8FC PUSH1 0x0 SLOAD SWAP1 DUP2 ISZERO MUL SWAP1 PUSH1 0x40 MLOAD PUSH1 0x0 PUSH1 0x40 MLOAD DUP1 DUP4 SUB DUP2 DUP6 DUP9 DUP9 CALL SWAP4 POP POP POP POP ISZERO DUP1 ISZERO PUSH2 0x643 JUMPI RETURNDATASIZE PUSH1 0x0 DUP1 RETURNDATACOPY RETURNDATASIZE PUSH1 0x0 REVERT JUMPDEST POP PUSH1 0x1 PUSH1 0x0 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND PUSH2 0x8FC SELFBALANCE SWAP1 DUP2 ISZERO MUL SWAP1 PUSH1 0x40 MLOAD PUSH1 0x0 PUSH1 0x40 MLOAD DUP1 DUP4 SUB DUP2 DUP6 DUP9 DUP9 CALL SWAP4 POP POP POP POP ISZERO DUP1 ISZERO PUSH2 0x6AC JUMPI RETURNDATASIZE PUSH1 0x0 DUP1 RETURNDATACOPY RETURNDATASIZE PUSH1 0x0 REVERT JUMPDEST POP POP JUMP JUMPDEST PUSH1 0x2 PUSH1 0x14 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH1 0xFF AND DUP2 JUMP JUMPDEST PUSH1 0x0 DUP1 PUSH1 0x2 DUP2 GT ISZERO PUSH2 0x6D1 JUMPI INVALID JUMPDEST PUSH1 0x2 PUSH1 0x14 SWAP1 SLOAD SWAP1 PUSH2 0x100 EXP SWAP1 DIV PUSH1 0xFF AND PUSH1 0x2 DUP2 GT ISZERO PUSH2 0x6EC JUMPI INVALID JUMPDEST EQ PUSH2 0x75F JUMPI PUSH1 0x40 MLOAD PUSH32 0x8C379A000000000000000000000000000000000000000000000000000000000 DUP2 MSTORE PUSH1 0x4 ADD DUP1 DUP1 PUSH1 0x20 ADD DUP3 DUP2 SUB DUP3 MSTORE PUSH1 0xE DUP2 MSTORE PUSH1 0x20 ADD DUP1 PUSH32 0x496E76616C69642073746174652E000000000000000000000000000000000000 DUP2 MSTORE POP PUSH1 0x20 ADD SWAP2 POP POP PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 REVERT JUMPDEST PUSH1 0x0 SLOAD PUSH1 0x2 MUL CALLVALUE EQ DUP1 PUSH2 0x771 JUMPI PUSH1 0x0 DUP1 REVERT JUMPDEST PUSH32 0xD5D55C8A68912E9A110618DF8D5E2E83B8D83211C57A8DDD1203DF92885DC881 PUSH1 0x40 MLOAD PUSH1 0x40 MLOAD DUP1 SWAP2 SUB SWAP1 LOG1 CALLER PUSH1 0x2 PUSH1 0x0 PUSH2 0x100 EXP DUP2 SLOAD DUP2 PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF MUL NOT AND SWAP1 DUP4 PUSH20 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF AND MUL OR SWAP1 SSTORE POP PUSH1 0x1 PUSH1 0x2 PUSH1 0x14 PUSH2 0x100 EXP DUP2 SLOAD DUP2 PUSH1 0xFF MUL NOT AND SWAP1 DUP4 PUSH1 0x2 DUP2 GT ISZERO PUSH2 0x7FD JUMPI INVALID JUMPDEST MUL OR SWAP1 SSTORE POP POP POP JUMP INVALID LOG2 PUSH6 0x627A7A723158 KECCAK256 0xA6 0xD2 DUP16 0xBB 0xA7 0xC2 0xBB CALLCODE 0xB8 0xCC SWAP12 KECCAK256 0xC3 0xB9 0x2E CALLDATALOAD INVALID 0xC1 ADDRESS 0xE8 0xD7 0xB2 SWAP11 REVERT PUSH3 0x261304 PUSH22 0x7CB6BA64736F6C634300051100320000000000000000 ",
"sourceMap": "71:2509:0:-;;;471:10;462:6;;:19;;;;;;;;;;;;;;;;;;511:1;499:9;:13;;;;;;491:5;:21;;;;545:9;535:5;;531:1;:9;530:24;522:58;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;71:2509;;;;;;"
}
"""
