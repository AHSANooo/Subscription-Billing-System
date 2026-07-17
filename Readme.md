# Subscription Billing System

A secure, gas-optimized, and modular on-chain subscription billing engine built with Solidity. Users pay recurring subscription fees using USDT (ERC-20), while the contract handles real-time access gating using time logic, dynamic expiry windows, and grace periods.

## 📋 Table of Contents
- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Smart Contracts](#smart-contracts)
- [Frontend](#frontend)
- [Tech Stack & Tooling](#tech-stack--tooling)
- [Installation & Setup](#installation--setup)
- [Usage](#usage)
- [Testing](#testing)
- [Deployment](#deployment)
- [Security Considerations](#security-considerations)
- [Gas Optimization](#gas-optimization)
- [License](#license)

## 📖 Overview

The Subscription Billing System is a Solidity-based smart contract system that enables decentralized subscription services with the following features:
- **Multi-tier Subscription Plans**: Support for multiple subscription tiers with different pricing, durations, and grace periods
- **Gas Optimization**: Storage-efficient mappings instead of arrays, custom error messages instead of require statements
- **Security-First Design**: Built with OpenZeppelin's Ownable and ReentrancyGuard, using SafeERC20 for token interactions
- **Access Control**: Owner-only administrative functions for plan management
- **Grace Period Handling**: Users retain access during grace periods after subscription expiry
- **Frontend Integration**: Next.js frontend with Wagmi/Viem for seamless wallet integration

## 🏗️ System Architecture

### Core Components

1. **ISubscriptionBilling.sol** - Interface defining the core subscription billing contract interface
2. **SubscriptionBilling.sol** - Main implementation contract implementing the subscription billing logic
3. **MockUSDT.sol** - Testing token that mimics USDT (6 decimals) for local development and testing

### Data Structures

```solidity
struct Plan {
    uint256 price;       // Price in 6-decimal notation (USDT)
    uint32 period;       // Subscription duration in seconds
    uint32 gracePeriod;  // Grace window duration in seconds
    bool isActive;       // Operational state flag for the plan tier
}
```

### Storage Architecture
- **Plans Storage**: `mapping(uint256 => Plan) public plans` - Stores plan configurations indexed by plan ID
- **User Subscriptions**: `mapping(address => mapping(uint256 => uint256)) public userExpiry` - Tracks user subscription expirations by plan

### Key Functions

**Administrative Functions** (Owner-only):
- `setPlan(uint256 _planId, uint256 _price, uint32 _period, uint32 _grace)` - Create or update subscription plans
- `togglePlanStatus(uint256 _planId, bool _isActive)` - Activate/deactivate subscription plans

**User Functions**:
- `subscribe(uint256 _planId)` - Initiate a new subscription for a plan
- `renew(uint256 _planId)` - Renew an existing subscription

**View Functions**:
- `isUserActive(address user, uint256 _planId)` - Check if user has active subscription
- `getExpiry(address user, uint256 _planId)` - Get subscription expiry timestamp

### Events
- `PlanUpdated(uint256 indexed planId, uint256 price, uint32 period, uint32 grace)` - Emitted when plans are created/updated
- `Subscribed(address indexed user, uint256 indexed planId, uint256 expiryTime)` - Emitted when user subscribes
- `Renewed(address indexed user, uint256 indexed planId, uint256 newExpiryTime)` - Emitted when subscription is renewed

## ⚙️ Smart Contracts

### SubscriptionBilling.sol
The main contract implementing the subscription billing logic with the following security features:
- **Reentrancy Protection**: Uses OpenZeppelin's ReentrancyGuard on state-changing functions
- **Access Control**: Owner-only administrative functions via Ownable
- **Safe ERC20 Interactions**: Uses OpenZeppelin's SafeERC20 library for USDT transfers
- **Custom Errors**: Gas-efficient error handling instead of traditional require() statements
- **Input Validation**: Comprehensive validation for plan parameters and user actions

Key Security Features:
- Non-reentrant subscription and renewal functions
- Owner-restricted administrative functions
- Zero-address validation for token contract
- State variable immutability where appropriate (USDT token address)
- Explicit visibility specifiers for all functions and state variables

### ISubscriptionBilling.sol
Defines the interface contract that specifies:
- Custom error types for gas-efficient error handling
- Events for subscription lifecycle tracking
- External function signatures for all public contract interactions
- View functions for subscription status querying

### MockUSDT.sol
A testing utility contract that simulates USDT behavior with 6 decimal precision for local development and testing environments.

## 💻 Frontend

The frontend is built with Next.js 16+ and provides a user interface for interacting with the subscription billing contracts.

### Key Features
- **Wallet Integration**: Built with Wagmi and Viem for seamless Ethereum wallet connections
- **TypeScript**: Full TypeScript support for enhanced developer experience
- **React Query**: Powerful data fetching and state management with @tanstack/react-query
- **Styling**: Tailwind CSS for responsive, utility-first styling
- **Next.js App Router**: Leveraging the latest Next.js features with the app directory structure

### Tech Stack
- **Framework**: Next.js 16.2.10
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Web3 Libraries**: Wagmi (v3.7.2), Viem (v2.55.2)
- **State Management**: React Query (v5.101.2)
- **UI Components**: Custom built with Tailwind CSS

## 🛠️ Tech Stack & Tooling

### Smart Contracts
- **Language**: Solidity ^0.8.20
- **Framework**: Foundry (Forge, Cast, Anvil, Chisel)
- **Security Libraries**: OpenZeppelin Contracts (AccessControl, ReentrancyGuard, SafeERC20)
- **Testing**: Forge test suite with Forge standard library

### Frontend
- **Framework**: Next.js 16.2.10 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Web3**: Wagmi v3.7.2, Viem v2.55.2
- **State Management**: @tanstack/react-query v5.101.2
- **Linting**: ESLint

### Development Tools
- **Foundry**: Compilation, testing, and deployment
- **Anvil**: Local Ethereum node for development
- **Cast**: Command-line interface for blockchain interaction
- **VS Code**: Primary development environment
- **Remix IDE**: Optional alternative development environment via Remixd

## ⚙️ Installation & Setup

### Prerequisites
- Node.js >= 18.x
- npm, yarn, pnpm, or bun
- Git
- Foundry (for smart contract development)

### Smart Contract Setup
```bash
# Clone the repository
git clone <repository-url>
cd Subscription-Billing-System/contracts

# Install dependencies (if any)
forge install

# Build the contracts
forge build

# Run tests
forge test

# Start local node for development
anvil
```

### Frontend Setup
```bash
# Navigate to frontend directory
cd ../frontend

# Install dependencies
npm install
# or
yarn install
# or
pnpm install
# or
bun install

# Start development server
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev

# Open in browser
Open http://localhost:3000
```

## 🚀 Usage

### Smart Contract Interaction

#### Deploying Contracts
1. Deploy USDT token contract (or use existing USDT address)
2. Deploy SubscriptionBilling contract with USDT token address as constructor parameter

#### Administrative Actions
1. **Set up subscription plans**:
   ```solidity
   // Example: Create a $10/month plan with 3-day grace period
   subscriptionBilling.setPlan(
       1,                    // planId
       10 * 10**6,           // $10 in 6-decimal USDT
       30 days,              // 30 day period
       3 days                // 3 day grace period
   );
   ```

2. **Manage plan status**:
   ```solidity
   // Activate plan
   subscriptionBilling.togglePlanStatus(1, true);
   
   // Deactivate plan
   subscriptionBilling.togglePlanStatus(1, false);
   ```

#### User Actions
1. **Subscribe to a plan**:
   ```solidity
   // Subscribe to plan ID 1
   subscriptionBilling.subscribe(1);
   ```

2. **Renew subscription**:
   ```solidity
   // Renew subscription for plan ID 1
   subscriptionBilling.renew(1);
   ```

3. **Check subscription status**:
   ```solidity
   // Check if user has active subscription
   bool isActive = subscriptionBilling.isUserActive(userAddress, 1);
   
   // Get expiry timestamp
   uint256 expiry = subscriptionBilling.getExpiry(userAddress, 1);
   ```

### Frontend Usage
The frontend provides a user interface for:
- Connecting Ethereum wallets (MetaMask, WalletConnect, etc.)
- Viewing available subscription plans
- Subscribing to plans
- Renewing subscriptions
- Checking subscription status
- Administrative functions (if connected as contract owner)

## 🧪 Testing

### Smart Contract Tests
Run the test suite with Forge:
```bash
cd contracts
forge test
```

The test suite includes:
- Unit tests for all contract functions
- Edge case testing (expired subscriptions, grace periods, etc.)
- Access control verification
- Reentrancy attack protection tests
- Gas optimization verification

### Frontend Testing
The frontend currently uses Next.js's built-in development tools. Additional testing can be added with:
- Jest for unit testing
- React Testing Library for component testing
- Cypress or Playwright for end-to-end testing

## 🚀 Deployment

### Local Development
1. Start local Ethereum node:
   ```bash
   anvil
   ```

2. Deploy contracts using Foundry script:
   ```bash
   forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --private-key <YOUR_PRIVATE_KEY> --broadcast
   ```

3. Update frontend configuration with deployed contract addresses

4. Start frontend development server:
   ```bash
   cd ../frontend
   npm run dev
   ```

### Production Deployment
1. Deploy to Ethereum L2 or sidechain (Polygon, Arbitrum, Optimism, etc.) for lower gas costs
2. Configure frontend environment variables with contract addresses
3. Deploy frontend to Vercel, Netlify, or similar platform
4. Set up monitoring and alerts for contract interactions

## 🔒 Security Considerations

### Implemented Security Measures
1. **Reentrancy Protection**: All state-changing functions use `nonReentrant` modifier
2. **Access Control**: Administrative functions restricted to contract owner via `onlyOwner` modifier
3. **Input Validation**: Comprehensive validation of all function parameters
4. **Safe Token Interactions**: Uses OpenZeppelin's SafeERC20 for all USDT interactions
5. **Immutable Dependencies**: USDT token address set in constructor and cannot be changed
6. **Custom Errors**: Uses custom errors instead of revert strings for gas efficiency
7. **Zero Address Checks**: Validates token contract address in constructor

### Recommended Additional Security Practices
1. **Third-party Audits**: Have the contracts audited by a reputable security firm before mainnet deployment
2. **Bug Bounty Program**: Consider launching a bug bounty program on platforms like Immunefi
3. **Time-locked Governance**: For future upgrades, consider implementing a timelock for administrative functions
4. **Event Monitoring**: Implement off-chain monitoring for critical events
5. **Upgradeability Considerations**: Current design is intentionally immutable; if upgradeability is needed, consider using UUPS or Transparent Proxy patterns with proper access controls

## ⛽ Gas Optimization

### Storage Optimization
- **Mapping over Arrays**: Uses mappings instead of arrays for plan and user storage to avoid iteration costs
- **Bit-packing**: Packs uint32 values for period and gracePeriod to save storage space
- **Immutable Variables**: USDT token address is declared as immutable to save gas on access

### Computational Optimization
- **Custom Errors**: Uses custom errors instead of revert strings to save gas on reverts
- **Cached Values**: Caches frequently accessed values like block.timestamp to reduce SLOAD operations
- **Efficient Data Structures**: Nested mappings for user-expiry lookups provide O(1) access time

### External Call Optimization
- **Batched Operations**: Where possible, operations are designed to minimize external calls
- **SafeERC20**: Uses OpenZeppelin's optimized SafeERC20 library for token transfers

### Estimated Gas Costs
- **Plan Creation**: ~80,000-100,000 gas
- **Plan Status Toggle**: ~40,000-50,000 gas
- **Subscription**: ~100,000-130,000 gas (includes token transfer)
- **Renewal**: ~80,000-110,000 gas (includes token transfer)
- **View Functions**: ~2,000-5,000 gas (no state modification)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- OpenZeppelin for their secure and audited smart contract libraries
- Foundry team for their excellent Ethereum development toolkit
- Vercel for the Next.js framework
- Wagmi and Viem teams for their excellent Web3 libraries
- The Ethereum developer community for continued innovation and collaboration

---

*Built with ❤️ for the decentralized economy*