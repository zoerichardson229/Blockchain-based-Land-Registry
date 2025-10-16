# 🏡 Blockchain-based Land Registry

A comprehensive smart contract system for managing property ownership, transfers, and documentation on the Stacks blockchain using Clarity.

## 🌟 Features

- **Property Registration** 📝 - Register new properties with detailed information
- **Ownership Management** 👥 - Track property owners and their holdings
- **Property Transfers** 🔄 - Secure property transfer system with pending/completed states
- **Marketplace Integration** 🏪 - List properties for sale and handle purchases
- **Document Storage** 📄 - Attach important documents to properties with cryptographic hashes
- **Valuation Updates** 💰 - Property owners can update their property valuations

## 🏗️ Contract Architecture

The contract uses several key data structures:

- `properties` - Core property information (owner, address, area, type, valuation)
- `property-transfers` - Transfer tracking system
- `property-documents` - Document hash storage
- `owner-properties` - Index of properties by owner

## 🚀 Usage

### Property Registration

Register a new property:

```clarity
(contract-call? .blockchain-based-land-registry register-property 
    "123 Main Street, City, State" 
    u1500 
    "Residential" 
    u250000)
```

### Property Transfer

Initiate a property transfer:

```clarity
(contract-call? .blockchain-based-land-registry initiate-transfer 
    u1 
    'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

Complete the transfer:

```clarity
(contract-call? .blockchain-based-land-registry complete-transfer u1)
```

### Marketplace Operations

List property for sale:

```clarity
(contract-call? .blockchain-based-land-registry list-property-for-sale 
    u1 
    u275000)
```

Purchase a property:

```clarity
(contract-call? .blockchain-based-land-registry purchase-property u1)
```

### Document Management

Add property documents:

```clarity
(contract-call? .blockchain-based-land-registry add-property-document 
    u1 
    0x1234567890abcdef1234567890abcdef12345678 
    "Title Deed")
```

## 📖 Read-Only Functions

- `get-property` - Get property details by ID
- `get-transfer` - Get transfer details by ID
- `get-owner-properties` - Get all properties owned by an address
- `get-current-property-id` - Get the latest property ID
- `get-property-document` - Get document information

## 🔧 Development

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js for testing

### Testing

Install dependencies:
```bash
npm install
```

Run tests:
```bash
npm test
```

### Contract Deployment

Check contract syntax:
```bash
clarinet check
```

Deploy to testnet:
```bash
clarinet deployments apply --network testnet
```

## 🛡️ Security Features

- **Owner Verification** - Only property owners can perform certain actions
- **Transfer Validation** - Prevents invalid transfers and self-transfers
- **Sale Verification** - Ensures properties are properly listed before purchase
- **Fund Verification** - Checks buyer has sufficient STX before purchase

## 📊 Contract Statistics

- **375+ lines** of clean Clarity code
- **9 public functions** for core operations
- **7 read-only functions** for data access
- **5 data maps** for efficient storage
- **Comprehensive error handling** with 9 error types

## 🎯 Error Codes

- `u100` - Unauthorized access
- `u101` - Property not found
- `u102` - Property already exists
- `u103` - Invalid transfer
- `u104` - Pending transfer
- `u105` - Not property owner
- `u106` - Invalid price
- `u107` - Property not for sale
- `u108` - Insufficient funds



## 📜 License

This project is open source and available under the MIT License.

# Blockchain-based Land Registry

