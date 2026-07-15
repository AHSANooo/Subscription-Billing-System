// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SubscriptionBilling.sol";
import "../src/MockUSDT.sol";

/**
 * @title DeployScript
 * @dev Automated deployment pipeline for local Anvil environments and public testnets.
 */
contract DeployScript is Script {
    
    function run() external {
        // Retrieve deployment key from environment context
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Open transaction broadcast window
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy MockUSDT with 1 million initial token supply (6-decimals scaled)
        MockUSDT usdt = new MockUSDT(1_000_000);
        console.log("MockUSDT deployed at address:", address(usdt));

        // 2. Deploy the core multi-tier Billing Engine, pointing to the new token contract
        SubscriptionBilling billingEngine = new SubscriptionBilling(address(usdt));
        console.log("SubscriptionBilling engine deployed at address:", address(billingEngine));

        // 3. Setup a standard Tier 1 Plan configuration (30 USDT, 30 Days, 3 Days Grace Window)
        uint256 planId = 1;
        uint256 planPrice = 30 * 10**6; // 6-decimal notation 
        uint32 planPeriod = 30 days;
        uint32 gracePeriod = 3 days;

        billingEngine.setPlan(planId, planPrice, planPeriod, gracePeriod);
        console.log("Tier 1 configuration successfully initialized on-chain.");

        // Close transaction broadcast window
        vm.stopBroadcast();
    }
}