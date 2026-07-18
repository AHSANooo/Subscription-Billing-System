# Subscription Billing System

A secure, gas-conscious on-chain subscription billing engine built with Solidity and a Next.js App Router frontend. The system is designed for USDT-denominated recurring payments, with subscription state, expiry windows, and grace periods handled on-chain.

## Table of Contents
- [Overview](#overview)
- [Project Layout](#project-layout)
- [Smart Contracts](#smart-contracts)
- [Frontend](#frontend)
- [Tech Stack and Tooling](#tech-stack-and-tooling)
- [Installation and Setup](#installation-and-setup)
- [Usage](#usage)
- [End-to-End Live Sandbox Testing Guide](#end-to-end-live-sandbox-testing-guide)
- [Testing](#testing)
- [Deployment](#deployment)
- [Security Considerations](#security-considerations)
- [Gas Optimization](#gas-optimization)
- [License](#license)

## Overview

This repository contains two coordinated pieces:

- A Foundry-based Solidity billing engine that tracks plan activation, subscription expiry, and grace-period access.
- A Next.js 16 frontend that reads contract state and submits subscription transactions through Wagmi and Viem.

The current contract flow supports:

- Multiple subscription plans with different prices and durations.
- Recurring renewal with grace-period continuity.
- Mock USDT testing via a 6-decimal ERC-20 token.
- Owner-managed plan creation and activation toggles.

## Project Layout

### Contracts

- `contracts/src/ISubscriptionBilling.sol` - contract interface, custom errors, events, and plan structure.
- `contracts/src/SubscriptionBilling.sol` - main subscription engine.
- `contracts/src/MockUSDT.sol` - 6-decimal ERC-20 test token with a public `mint` helper.
- `contracts/script/Deploy.s.sol` - deploys MockUSDT, deploys SubscriptionBilling, and seeds plan `1`.
- `contracts/test/SubscriptionBilling.t.sol` - Foundry tests for subscription, renewal, and grace-period behavior.

### Frontend

- `frontend/app/layout.tsx` - root App Router layout.
- `frontend/app/providers.tsx` - Wagmi and React Query provider wrapper.
- `frontend/app/page.tsx` - dashboard UI for wallet connection, token approval, and subscription actions.
- `frontend/src/web3/config.ts` - chain and transport configuration.
- `frontend/src/web3/constants.ts` - deployed addresses and contract ABIs.

## Smart Contracts

### SubscriptionBilling.sol

Core behavior:

- `setPlan(uint256 _planId, uint256 _price, uint32 _period, uint32 _grace)` creates or updates a plan.
- `togglePlanStatus(uint256 _planId, bool _isActive)` enables or disables a plan.
- `subscribe(uint256 _planId)` starts a new subscription and transfers the plan price in USDT.
- `renew(uint256 _planId)` extends an active or recently expired subscription.
- `isUserActive(address user, uint256 _planId)` checks whether access is currently open.
- `getExpiry(address user, uint256 _planId)` returns the stored expiry timestamp.

Implementation notes:

- Uses `Ownable` for administrative control.
- Uses `ReentrancyGuard` on state-changing user actions.
- Uses `SafeERC20` for token transfers.
- Stores plan state in `mapping(uint256 => Plan)` and user expiry in `mapping(address => mapping(uint256 => uint256))`.

### ISubscriptionBilling.sol

The interface defines the plan struct, custom errors, events, and external function signatures used by the contract and frontend ABI layer.

### MockUSDT.sol

This token mirrors USDT-style 6-decimal behavior and includes a public `mint(address to, uint256 amount)` helper for test and sandbox use.

## Frontend

The frontend uses the Next.js App Router with a client-side provider layer for wallet and query state.

Key features:

- Wallet connection through Wagmi.
- Contract reads for balance, allowance, active status, and expiry.
- Approval flow for the USDT token before subscription execution.
- Clean, minimal dashboard state for subscribe and renew actions.

The frontend is wired to the deployed addresses in `frontend/src/web3/constants.ts` and uses the ABIs generated from the Solidity contract surface.

## Tech Stack and Tooling

### Contracts

- Solidity `^0.8.20`
- Foundry: Forge, Cast, and Anvil
- OpenZeppelin Contracts

### Frontend

- Next.js `16.2.10`
- TypeScript
- Wagmi `3.7.2`
- Viem `2.55.2`
- React Query `5.101.2`
- Tailwind CSS

### Development Tools

- VS Code
- Git
- Anvil for local blockchain simulation

## Installation and Setup

### Prerequisites

- Node.js 18 or newer
- npm
- Foundry installed and available on your PATH

### Smart Contract Setup

```bash
cd contracts
forge build
forge test
```

### Frontend Setup

```bash
cd frontend
npm install
npm run build
npm run dev
```

## Usage

### Local Development Flow

1. Start a local chain with Anvil.
2. Deploy the contracts using `contracts/script/Deploy.s.sol`.
3. Update the frontend constants if you deploy to a different network or address set.
4. Run the frontend and connect a wallet pointed at the matching network.

### Contract Interaction Examples

```solidity
// Create a 30 USDT plan with a 30 day period and 3 day grace period
subscriptionBilling.setPlan(1, 30 * 10**6, 30 days, 3 days);

// Enable or disable the plan
subscriptionBilling.togglePlanStatus(1, true);

// Start or renew a subscription
subscriptionBilling.subscribe(1);
subscriptionBilling.renew(1);
```

## End-to-End Live Sandbox Testing Guide

Follow these steps to simulate a live corporate subscription flow on Sepolia without spending real funds.

### Prerequisite Configuration

1. Open your wallet extension, such as MetaMask or Rabby, and switch to Sepolia.
2. Claim free Sepolia gas from a public faucet such as Google Cloud Sepolia Faucet or Alchemy Faucet.

### Step 1: Mint Mock USDT Test Tokens

Use the verified MockUSDT contract on Sepolia to mint test funds:

1. Open the verified [MockUSDT token contract on Etherscan](https://sepolia.etherscan.io/address/0xeCd399Aa572a874AdB04544A65675916FD4e6c75#writeContract).
2. Click **Connect to Web3** and connect your wallet.
3. Open the `mint` function.
4. Set `to` to your wallet address.
5. Set `amount` to `1000000000`, which equals `1,000.00 USDT` with 6-decimal precision.
6. Submit the transaction and confirm it in your wallet.

### Step 2: Execute Dashboard Operations

1. Open your deployed frontend dashboard.
2. Connect the same wallet you used for minting.
3. Confirm the wallet balance shows `1,000.00 USDT`.
4. Click **Approve Core USDT Operations**.
5. After approval confirms, click **Subscribe to Tier 1**.
6. The interface should show an active subscription state and a synchronized expiry timestamp.

## Testing

### Smart Contract Tests

```bash
cd contracts
forge test
```

### Frontend Build Check

```bash
cd frontend
npm run build
```

The frontend build is the quickest way to verify the App Router, provider layer, and ABI wiring are aligned.

## Deployment

### Local Deployment

```bash
cd contracts
PRIVATE_KEY=<YOUR_PRIVATE_KEY> forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast
```

After deployment, point the frontend constants at the deployed token and subscription contract addresses.

### Sepolia or Other Public Testnets

1. Deploy MockUSDT and SubscriptionBilling to the target testnet.
2. Seed the tier configuration with the deployment script or a one-off admin transaction.
3. Update `frontend/src/web3/constants.ts` with the deployed addresses.
4. Rebuild and redeploy the frontend.

### Live Deployments (Sepolia Testnet)
- **Live Interactive Dashboard**: [subscription-billing-system.vercel.app](https://subscription-billing-system.vercel.app/)
- Core Billing Engine: `0x6214f6D729d560286389ff741eDcc794Ec5A522c`
- Mock USDT Token Asset: `0xeCd399Aa572a874AdB04544A65675916FD4e6c75`

## Security Considerations

### Implemented Security Measures

- Reentrancy protection on subscription mutations.
- Owner-restricted administrative functions.
- Safe ERC-20 transfers through OpenZeppelin.
- Custom errors for leaner revert paths.
- Zero-address validation in the constructor.

### Operational Guidance

- Review any deployed address before signing approvals.
- Keep the frontend constants aligned with the active network.
- Treat Sepolia and local Anvil deployments as sandbox environments only.

## Gas Optimization

- Uses mappings instead of arrays for direct lookups.
- Packs plan timing values into `uint32` fields.
- Caches `block.timestamp` in mutation paths where useful.
- Uses custom errors instead of revert strings.
- Uses immutable token wiring for the USDT address.

## License

This project is licensed under the MIT License. See the root LICENSE file for the full terms.
