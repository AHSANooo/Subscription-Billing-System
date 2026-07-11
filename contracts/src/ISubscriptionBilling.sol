// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ISubscriptionBilling
 * @dev Interface for the secure, gas-optimized Multi-Tier USDT Subscription Billing Contract.
 */
interface ISubscriptionBilling {
    
    struct Plan {
        uint256 price;       // Price in 6-decimal notation (USDT)
        uint32 period;       // Subscription duration in seconds
        uint32 gracePeriod;  // Grace window duration in seconds
        bool isActive;       // Operational state flag for the plan tier
    }

    // --- Custom Errors (Gas-Optimized & Explicit) ---
    error InvalidPlanPrice();
    error InvalidPlanPeriod();
    error SubscriptionExpired();
    error PlanActive();
    error PlanNotActive();
    error ZeroAddress();

    // --- Events ---
    event PlanUpdated(uint256 indexed planId, uint256 price, uint32 period, uint32 grace);
    event Subscribed(address indexed user, uint256 indexed planId, uint256 expiryTime);
    event Renewed(address indexed user, uint256 indexed planId, uint256 newExpiryTime);

    // --- External Functions ---
    function setPlan(uint256 _planId, uint256 _price, uint32 _period, uint32 _grace) external;
    function subscribe(uint256 _planId) external;
    function renew(uint256 _planId) external;
    
    // --- View Functions ---
    function isUserActive(address user, uint256 _planId) external view returns (bool);
    function getExpiry(address user, uint256 _planId) external view returns (uint256);
}