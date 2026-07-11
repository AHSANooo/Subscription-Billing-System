// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ISubscriptionBilling.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SubscriptionBilling
 * @dev High-performance recurring billing engine engineered for 6-decimal USDT transactions.
 */
contract SubscriptionBilling is ISubscriptionBilling, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- State Variables ---
    IERC20 public immutable usdtToken;
    
    // Storage Slot 1
    uint256 public planPrice;     // Stored in 6-decimal notation (1 USDT = 1,000,000)
    
    // Storage Slot 2: Packed variables (uint32 + uint32 fit cleanly into one 256-bit slot)
    uint32 public planPeriod;     // Duration in seconds (e.g., 30 days = 2,592,000)
    uint32 public gracePeriod;    // Duration in seconds (e.g., 3 days = 259,200)

    // Storage Slot 3+
    mapping(address => uint256) public userExpiry;

    /**
     * @dev Sets up the token link and configures initial payment matrices.
     */
    constructor(
        address _usdtToken,
        uint256 _initialPrice,
        uint32 _initialPeriod,
        uint32 _initialGrace
    ) Ownable(msg.sender) {
        if (_usdtToken == address(0)) revert ZeroAddress();
        usdtToken = IERC20(_usdtToken);
        _setPlan(_initialPrice, _initialPeriod, _initialGrace);
    }

    // --- External Administrative Routines ---

    /**
     * @dev Updates pricing structures and window intervals dynamically. Guarded against reentrancy.
     */
    function setPlan(uint256 _price, uint32 _period, uint32 _grace) external override onlyOwner nonReentrant {
        _setPlan(_price, _period, _grace);
    }

    // --- Core User Transactions ---

    /**
     * @dev Process new incoming subscriptions. SafeERC20 guards against irregular token variants.
     */
    function subscribe() external override nonReentrant {
        uint256 price = planPrice;
        if (price == 0) revert InvalidPlanPrice();

        address subscriber = msg.sender;
        uint256 currentExpiry = userExpiry[subscriber];
        uint256 currentTime = block.timestamp; // Cache variable access to save SLOAD gas

        // Use precise error handling instead of generic unauthorized reverts
        if (currentExpiry != 0 && currentTime <= currentExpiry + gracePeriod) {
            revert PlanActive(); 
        }

        uint256 newExpiry = currentTime + planPeriod;
        userExpiry[subscriber] = newExpiry;

        emit Subscribed(subscriber, newExpiry);

        usdtToken.safeTransferFrom(subscriber, address(this), price);
    }

    /**
     * @dev Process renewals. Determines mathematical behavior based on current active/expired thresholds.
     */
    function renew() external override nonReentrant {
        uint256 price = planPrice;
        if (price == 0) revert InvalidPlanPrice();

        address subscriber = msg.sender;
        uint256 currentExpiry = userExpiry[subscriber];
        if (currentExpiry == 0) revert SubscriptionExpired();

        uint256 currentTime = block.timestamp; // Cache variable access
        uint256 newExpiry;

        // Mathematical rules: Stacks if early/grace, resets if completely dead.
        if (currentTime <= currentExpiry + gracePeriod) {
            newExpiry = currentExpiry + planPeriod;
        } else {
            newExpiry = currentTime + planPeriod;
        }

        userExpiry[subscriber] = newExpiry;
        emit Renewed(subscriber, newExpiry);

        usdtToken.safeTransferFrom(subscriber, address(this), price);
    }

    // --- High-Efficiency Read Paths ---

    /**
     * @dev Dynamic eligibility access gating evaluation. Boundary inclusion evaluation follows strict <= rule.
     */
    function isActive(address user) external view override returns (bool) {
        uint256 expiry = userExpiry[user];
        if (expiry == 0) return false;
        return block.timestamp <= expiry + gracePeriod;
    }

    function getExpiry(address user) external view override returns (uint256) {
        return userExpiry[user];
    }

    // --- Private Internal Realignment Engines ---

    function _setPlan(uint256 _price, uint32 _period, uint33 _grace) private {
        if (_price == 0) revert InvalidPlanPrice();
        if (_period == 0) revert InvalidPlanPeriod();
        
        planPrice = _price;
        planPeriod = _period;
        gracePeriod = _grace;

        emit PlanUpdated(_price, _period, _grace);
    }
}