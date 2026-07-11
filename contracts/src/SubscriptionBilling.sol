// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ISubscriptionBilling.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SubscriptionBilling
 * @dev Highly modular, tier-based recurring billing engine for 6-decimal USDT transactions.
 */
contract SubscriptionBilling is ISubscriptionBilling, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- State Variables ---
    IERC20 public immutable usdtToken;
    
    // Plan lookup configuration registry
    mapping(uint256 => Plan) public plans;

    // Nested tracking mapping: User Address => Plan ID => Expiration Timestamp
    mapping(address => mapping(uint256 => uint256)) public userExpiry;

    /**
     * @dev Configures the target token for ERC-20 payment transfers.
     */
    constructor(address _usdtToken) Ownable(msg.sender) {
        if (_usdtToken == address(0)) revert ZeroAddress();
        usdtToken = IERC20(_usdtToken);
    }

    // --- External Administrative Routines ---

    /**
     * @dev Configures or modifies a subscription plan tier. Formatted explicitly to pack uint32 structures.
     */
    function setPlan(
        uint256 _planId, 
        uint256 _price, 
        uint32 _period, 
        uint32 _grace
    ) external override onlyOwner nonReentrant {
        if (_price == 0) revert InvalidPlanPrice();
        if (_period == 0) revert InvalidPlanPeriod();
        
        plans[_planId] = Plan({
            price: _price,
            period: _period,
            gracePeriod: _grace,
            isActive: true
        });

        emit PlanUpdated(_planId, _price, _period, _grace);
    }

    // --- Core User Transactions ---

    /**
     * @dev Processes new incoming subscriptions for a specific plan tier.
     */
    function subscribe(uint256 _planId) external override nonReentrant {
        Plan memory plan = plans[_planId];
        if (!plan.isActive) revert PlanNotActive();

        address subscriber = msg.sender;
        uint256 currentExpiry = userExpiry[subscriber][_planId];
        uint256 currentTime = block.timestamp; // Cache timestamp execution state to minimize SLOAD costs

        if (currentExpiry != 0 && currentTime <= currentExpiry + plan.gracePeriod) {
            revert PlanActive(); 
        }

        uint256 newExpiry = currentTime + plan.period;
        userExpiry[subscriber][_planId] = newExpiry;

        emit Subscribed(subscriber, _planId, newExpiry);

        usdtToken.safeTransferFrom(subscriber, address(this), plan.price);
    }

    /**
     * @dev Renews an active or recently expired subscription for a plan tier.
     */
    function renew(uint256 _planId) external override nonReentrant {
        Plan memory plan = plans[_planId];
        if (!plan.isActive) revert PlanNotActive();

        address subscriber = msg.sender;
        uint256 currentExpiry = userExpiry[subscriber][_planId];
        if (currentExpiry == 0) revert SubscriptionExpired();

        uint256 currentTime = block.timestamp; // Cache timestamp access
        uint256 newExpiry;

        // Cumulative chronological tracking rules
        if (currentTime <= currentExpiry + plan.gracePeriod) {
            newExpiry = currentExpiry + plan.period;
        } else {
            newExpiry = currentTime + plan.period;
        }

        userExpiry[subscriber][_planId] = newExpiry;
        emit Renewed(subscriber, _planId, newExpiry);

        usdtToken.safeTransferFrom(subscriber, address(this), plan.price);
    }

    // --- High-Efficiency Read Paths ---

    /**
     * @dev Evaluates whether a user's subscription access window is open (inclusive of the grace period).
     */
    function isUserActive(address user, uint256 _planId) external view override returns (bool) {
        uint256 expiry = userExpiry[user][_planId];
        if (expiry == 0) return false;
        return block.timestamp <= expiry + plans[_planId].gracePeriod;
    }

    /**
     * @dev Returns the explicit timestamp expiration of a user's subscription tier.
     */
    function getExpiry(address user, uint256 _planId) external view override returns (uint256) {
        return userExpiry[user][_planId];
    }
}