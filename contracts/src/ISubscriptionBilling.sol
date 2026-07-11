// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISubscriptionBilling
 * @dev Interface for the secure, gas-optimized USDT Subscription Billing Contract.
 */
interface ISubscriptionBilling {
    
    // --- Custom Errors (Gas-Optimized) ---
    error DepositAmountZero();
    error InvalidPlanPrice();
    error InvalidPlanPeriod();
    error TransferFailed();
    error SubscriptionExpired();
    error Unauthorized();

    // --- Events ---
    event PlanUpdated(uint256 price, uint256 period, uint256 grace);
    event Subscribed(address indexed user, uint256 expiryTime);
    event Renewed(address indexed user, uint256 newExpiryTime);

    // --- External Functions ---
    function setPlan(uint256 _price, uint256 _period, uint256 _grace) external;
    function subscribe() external;
    function renew() external;
    
    // --- View Functions ---
    function isActive(address user) external view returns (bool);
    function getExpiry(address user) external view returns (uint256);
}