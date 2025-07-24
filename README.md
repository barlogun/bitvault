# BitVault Pro

<div align="center">

![BitVault Pro](https://img.shields.io/badge/BitVault-Pro-orange?style=for-the-badge)
![Stacks](https://img.shields.io/badge/Stacks-Blockchain-purple?style=for-the-badge)
![Clarity](https://img.shields.io/badge/Clarity-Smart_Contract-blue?style=for-the-badge)
![License](https://img.shields.io/badge/License-ISC-green?style=for-the-badge)

**Next-Generation Bitcoin-Backed Stablecoin Infrastructure**

*Revolutionizing Bitcoin utility through intelligent collateral management and decentralized stablecoin minting*

</div>

## 🌟 Overview

BitVault Pro is a sophisticated DeFi protocol built on the Stacks blockchain that enables Bitcoin holders to unlock liquidity by minting USD-pegged stablecoins (BVLT) against their BTC collateral while maintaining their Bitcoin exposure. The protocol creates a secure bridge between HODLing and active DeFi participation through intelligent collateral management and real-time risk assessment.

### 🎯 Key Features

- **🔐 Over-Collateralized Loans**: Mint BVLT stablecoins with 150% minimum collateralization ratio
- **⚡ Automated Interest Accrual**: Dynamic interest calculations based on block-by-block compounding
- **🛡️ Liquidation Protection**: Advanced risk management with 120% liquidation threshold
- **📊 Oracle Integration**: Real-time BTC price feeds with staleness protection
- **🔄 Position Management**: Flexible collateral deposits, withdrawals, and debt repayment
- **🏛️ Governance Controls**: Protocol ownership and emergency pause mechanisms

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Protocol Parameters](#-protocol-parameters)
- [Smart Contract Functions](#-smart-contract-functions)
- [Installation](#-installation)
- [Testing](#-testing)
- [Usage Examples](#-usage-examples)
- [Security Considerations](#-security-considerations)
- [Risk Parameters](#-risk-parameters)
- [Deployment](#-deployment)
- [Contributing](#-contributing)
- [License](#-license)

## 🏗️ Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                     BitVault Pro Protocol                   │
├─────────────────────────────────────────────────────────────┤
│  Collateral Management  │  Debt Tracking  │  Risk Engine   │
├─────────────────────────────────────────────────────────────┤
│           Interest Accrual System & Oracle Feeds            │
├─────────────────────────────────────────────────────────────┤
│         Liquidation Engine & Governance Controls            │
└─────────────────────────────────────────────────────────────┘
```

### Data Structures

- **Positions**: User collateral and debt tracking with interest accrual
- **Global State**: Protocol-wide metrics and fee accumulation
- **Oracle Data**: BTC price feeds with timestamp validation
- **Fungible Token**: BVLT stablecoin implementation

## ⚙️ Protocol Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Minimum Collateral Ratio** | 150% | Required over-collateralization |
| **Liquidation Threshold** | 120% | Position becomes liquidatable |
| **Liquidation Penalty** | 10% | Fee charged during liquidation |
| **Minimum Loan Amount** | 100 BVLT | Smallest debt position allowed |
| **Price Feed Expiry** | 24 hours | Maximum oracle data staleness |
| **Interest Rate** | 0.0005% per block | Compound interest on debt |

## 📚 Smart Contract Functions

### 🔧 Administrative Functions

#### `set-protocol-owner`

Transfer protocol ownership to a new address.

```clarity
(set-protocol-owner new-owner)
```

#### `pause-protocol`

Emergency pause mechanism for crisis management.

```clarity
(pause-protocol true/false)
```

#### `update-btc-price`

Update oracle price feed (owner only).

```clarity
(update-btc-price price timestamp)
```

### 💰 Core User Functions

#### `open-position`

Open a new collateralized debt position or expand existing one.

```clarity
(open-position btc-amount bvlt-amount)
```

#### `deposit-collateral`

Add additional BTC collateral to strengthen position.

```clarity
(deposit-collateral btc-amount)
```

#### `repay-debt`

Repay BVLT debt to reduce position liability.

```clarity
(repay-debt amount)
```

#### `withdraw-collateral`

Withdraw BTC collateral while maintaining safe collateralization.

```clarity
(withdraw-collateral btc-amount)
```

#### `liquidate-position`

Liquidate undercollateralized positions for rewards.

```clarity
(liquidate-position target-user)
```

### 📊 Read-Only Functions

#### `get-user-position`

Retrieve detailed user position information.

```clarity
(get-user-position user)
```

#### `get-collateralization-ratio`

Calculate current position collateralization ratio.

```clarity
(get-collateralization-ratio user)
```

#### `get-protocol-metrics`

Get comprehensive protocol health metrics.

```clarity
(get-protocol-metrics)
```

#### `is-liquidatable`

Check if a position is eligible for liquidation.

```clarity
(is-liquidatable user)
```

## 🚀 Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) >= 2.0.0
- [Node.js](https://nodejs.org/) >= 18.0.0
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)

### Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/barlogun/bitvault.git
   cd bitvault
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Initialize Clarinet environment**

   ```bash
   clarinet check
   ```

## 🧪 Testing

### Run Test Suite

```bash
# Run all tests
npm test

# Run tests with coverage and gas costs
npm run test:report

# Watch mode for development
npm run test:watch

# Clarinet contract validation
clarinet check
```

### Test Structure

```
tests/
├── bitvault.test.ts          # Main contract tests
├── integration/              # Integration test scenarios
├── scenarios/               # Complex user workflows
└── helpers/                 # Test utilities
```

## 💡 Usage Examples

### Opening a Position

```typescript
// Open position with 1 BTC collateral, mint 30,000 BVLT
const txOpen = simnet.callPublicFn(
  "bitvault",
  "open-position",
  [Cl.uint(100000000), Cl.uint(3000000000000)], // 1 BTC, 30k BVLT
  address1
);
```

### Managing Collateral

```typescript
// Deposit additional 0.5 BTC collateral
const txDeposit = simnet.callPublicFn(
  "bitvault",
  "deposit-collateral",
  [Cl.uint(50000000)], // 0.5 BTC
  address1
);

// Withdraw 0.2 BTC collateral
const txWithdraw = simnet.callPublicFn(
  "bitvault",
  "withdraw-collateral",
  [Cl.uint(20000000)], // 0.2 BTC
  address1
);
```

### Debt Management

```typescript
// Repay 5,000 BVLT debt
const txRepay = simnet.callPublicFn(
  "bitvault",
  "repay-debt",
  [Cl.uint(500000000000)], // 5k BVLT
  address1
);
```

### Position Monitoring

```typescript
// Check user position
const position = simnet.callReadOnlyFn(
  "bitvault",
  "get-user-position",
  [Cl.principal(address1)],
  address1
);

// Check collateralization ratio
const ratio = simnet.callReadOnlyFn(
  "bitvault",
  "get-collateralization-ratio",
  [Cl.principal(address1)],
  address1
);
```

## 🔒 Security Considerations

### Access Controls

- Protocol owner-only functions for critical operations
- Emergency pause mechanism for crisis management
- User authorization checks for position modifications

### Risk Management

- Over-collateralization requirements (150% minimum)
- Liquidation threshold protection (120%)
- Oracle price feed staleness validation
- Interest rate limits and precision controls

### Economic Security

- Liquidation penalties discourage undercollateralization
- Automated interest accrual maintains protocol solvency
- Global debt tracking prevents system insolvency

## ⚠️ Risk Parameters

### Collateralization Requirements

- **Minimum Ratio**: 150% (debt cannot exceed 66.67% of collateral value)
- **Liquidation Threshold**: 120% (positions liquidated below this ratio)
- **Safety Buffer**: 30% margin between minimum and liquidation ratios

### Interest & Fees

- **Base Interest Rate**: 0.0005% per block (~2.6% annually)
- **Liquidation Penalty**: 10% of collateral value
- **Stability Fees**: Accumulated from interest and penalties

### Oracle Dependencies

- **Price Feed Staleness**: 24-hour maximum
- **Price Validation**: Non-zero price requirements
- **Fallback Mechanisms**: Contract pausing on oracle failures

## 🚀 Deployment

### Testnet Deployment

1. **Configure network settings**

   ```bash
   # Edit settings/Testnet.toml
   clarinet integrate
   ```

2. **Deploy contract**

   ```bash
   clarinet deploy --testnet
   ```

3. **Initialize protocol**

   ```bash
   # Set initial BTC price and configure parameters
   clarinet console --testnet
   ```

### Mainnet Deployment

```bash
# Production deployment checklist
1. Security audit completion
2. Oracle integration testing
3. Economic parameter validation
4. Emergency procedures documentation
5. Multi-sig governance setup

clarinet deploy --mainnet
```

## 📊 Protocol Metrics

### Key Performance Indicators

- **Total Value Locked (TVL)**: Sum of all BTC collateral
- **Outstanding Debt**: Total BVLT tokens in circulation
- **Collateralization Ratio**: System-wide health metric
- **Stability Fees**: Protocol revenue accumulation
- **Liquidation Events**: Risk management effectiveness

### Monitoring Dashboards

Track protocol health through:

- Real-time collateralization ratios
- Oracle price feed status
- Interest accrual rates
- Liquidation queue monitoring

## 🤝 Contributing

We welcome contributions to BitVault Pro! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`npm test`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Code Standards

- Follow Clarity best practices
- Maintain comprehensive test coverage
- Document all public functions
- Use consistent naming conventions
- Include gas optimization considerations

## 📄 License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links & Resources

- **Documentation**: [BitVault Pro Docs](https://docs.bitvault.pro)
- **Stacks Blockchain**: [https://stacks.co](https://stacks.co)
- **Clarity Language**: [https://clarity-lang.org](https://clarity-lang.org)
- **Clarinet Tool**: [https://github.com/hirosystems/clarinet](https://github.com/hirosystems/clarinet)

## ⚡ Quick Start

```bash
# Clone and setup
git clone https://github.com/barlogun/bitvault.git
cd bitvault
npm install

# Run tests
npm test

# Check contracts
clarinet check

# Start development
npm run test:watch
```
