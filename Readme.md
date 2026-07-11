# Subscription Billing System

A secure, gas-optimized, and modular on-chain subscription billing engine built with Solidity. Users pay recurring subscription fees using USDT (ERC-20), while the contract handles real-time access gating using time logic, dynamic expiry windows, and grace periods.

## System Architecture
- **ISubscriptionBilling.sol**: Interface declaring core system custom errors, events, and external specifications.
- **SubscriptionBilling.sol**: Main administration and logic execution contract implementing OpenZeppelin security primitives.
- **MockUSDT.sol**: A 6-decimal testing token replicating live network configurations.

## Core Optimization & Reliability Metrics
- **Minimal Storage Overhead**: Eliminates dense arrays; maps states directly to address hashes to keep storage reads/writes gas-efficient.
- **Pre-flight Execution Safety**: The companion Next.js UI executes static transaction simulations via `eth_call`, eliminating gas expenditures on failing state actions.
- **Custom Error Blocks**: Swaps expensive string-based `require` checks for lightweight custom errors.

## Tech Stack & Tooling
- **Smart Contracts**: Solidity ^0.8.x, Foundry Framework, OpenZeppelin Libraries
- **Development Environment**: Ubuntu Linux, VS Code, Remix IDE via Remixd daemon
- **Frontend**: Next.js, Node.js, Viem, Wagmi