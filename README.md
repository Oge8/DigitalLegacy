# DigitalLegacy: Cross-Chain Decentralized Will Executor

DigitalLegacy is a smart contract solution that enables secure and automated distribution of digital assets across multiple blockchains according to predetermined instructions, functioning as a decentralized will executor.

## Overview

The DigitalLegacy smart contract provides a trustless mechanism for digital asset inheritance, allowing users to specify beneficiaries and distribution rules that are automatically executed after a period of account inactivity. The system incorporates multi-signature guardian oversight and cross-chain asset distribution capabilities.

## Key Features

### Time-Locked Execution
- Automated trigger based on account inactivity period
- Customizable inactivity threshold
- Activity monitoring through blockchain height

### Multi-Signature Guardian System
- Required minimum of 2 guardian approvals for distribution
- Guardian management system
- Approval tracking mechanism

### Cross-Chain Distribution
- Support for multiple blockchain networks
- Integration with cross-chain bridges
- Secure transfer verification system
- Custom address mapping for different chains

### Asset Management
- Support for multiple asset types:
  - Native STX tokens
  - Fungible tokens (FT)
  - Non-fungible tokens (NFT)
- Percentage-based distribution rules
- Up to 200 distribution rules per beneficiary
- Support for up to 10 cross-chain addresses per beneficiary

## Smart Contract Functions

### Initialization and Setup
- `initialize`: Set up the contract with an inactivity threshold
- `add-guardian`: Register authorized guardians
- `add-beneficiary`: Add beneficiaries and their distribution rules
- `add-or-update-supported-chain`: Configure supported blockchain networks

### Asset Distribution
- `approve-distribution`: Guardian approval for asset distribution
- `execute-distribution`: Trigger the distribution process
- `transfer-stx`: Transfer STX tokens
- `transfer-ft`: Transfer fungible tokens
- `transfer-ft`: Transfer non-fungible tokens

### Cross-Chain Management
- `add-cross-chain-beneficiary`: Register cross-chain addresses for beneficiaries
- `confirm-cross-chain-transfer`: Verify cross-chain transfers
- `generate-transfer-id`: Create unique transfer identifiers

### Monitoring and Status
- `get-last-activity`: Check the last recorded activity
- `get-beneficiary-distribution`: View distribution rules
- `get-guardian-status`: Check guardian authorization
- `get-chain-status`: View supported chain configuration
- `get-transfer-status`: Monitor cross-chain transfers
- `check-distribution-ready`: Verify distribution requirements

## Error Codes

- `ERR-NOT-AUTHORIZED (u100)`: Unauthorized access attempt
- `ERR-ALREADY-INITIALIZED (u101)`: Contract already initialized
- `ERR-INVALID-BENEFICIARY (u102)`: Invalid beneficiary address
- `ERR-INSUFFICIENT-GUARDIANS (u103)`: Not enough guardian approvals
- `ERR-NOT-ACTIVE (u104)`: Inactivity threshold not met
- `ERR-INVALID-CHAIN (u105)`: Unsupported blockchain network
- `ERR-BRIDGE-ERROR (u106)`: Cross-chain bridge operation failed
- `ERR-LIST-FULL (u107)`: Maximum list capacity reached
- `ERR-NO-BRIDGE-CONTRACT (u108)`: Bridge contract not configured

## Security Considerations

1. **Multi-Signature Protection**: Requires multiple guardian approvals before executing distributions
2. **Time-Lock Mechanism**: Ensures distributions only occur after verified inactivity
3. **Owner Controls**: Critical functions restricted to contract owner
4. **Cross-Chain Security**: Verification system for cross-chain transfers
5. **Capacity Limits**: Protected against overflow through list size restrictions

## Usage Example

1. Contract owner initializes the contract with an inactivity threshold
2. Owner adds guardians for oversight
3. Owner registers beneficiaries with distribution rules
4. Owner configures supported chains and bridge contracts
5. Owner adds cross-chain addresses for beneficiaries
6. Upon inactivity, guardians approve distribution
7. Contract executes asset distribution across specified chains

## Technical Requirements

- Clarity Smart Contract
- Compatible with Stacks blockchain
- Requires integration with cross-chain bridge contracts
- Supports NFT and FT trait interfaces
