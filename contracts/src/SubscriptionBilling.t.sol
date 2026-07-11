// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SubscriptionBilling.sol";
import "../src/MockUSDT.sol";

contract SubscriptionBillingTest is Test {
    SubscriptionBilling public billing;
    MockUSDT public usdt;

    address public owner = address(0x1);
    address public subscriber = address(0x2);

    // Test parameters structured to 6-decimal standards
    uint256 public price = 30 * 10**6; // 30 USDT
    uint32 public period = 30 days;
    uint32 public grace = 3 days;

    function setUp() public {
        // Deploy testing assets from owner context
        vm.startPrank(owner);
        usdt = new MockUSDT(1_000_000); // Mint initial supply
        billing = new SubscriptionBilling(address(usdt), price, period, grace);
        vm.stopPrank();

        // Fund subscriber wallet and approve the contract interface
        usdt.mint(subscriber, 1000 * 10**6);
        vm.prank(subscriber);
        usdt.approve(address(billing), type(uint256).max);
    }

    function test_InitialSubscriptionPath() public {
        vm.prank(subscriber);
        billing.subscribe();

        assertTrue(billing.isActive(subscriber));
        assertEq(billing.getExpiry(subscriber), block.timestamp + period);
    }

    function test_FailDoubleSubscribeWhileActive() public {
        vm.startPrank(subscriber);
        billing.subscribe();
        
        // Assert that a second direct subscribe call reverts with a custom error
        vm.expectRevert(ISubscriptionBilling.PlanActive.selector);
        billing.subscribe();
        vm.stopPrank();
    }

    function test_RenewBeforeExpiryStacksChronology() public {
        vm.startPrank(subscriber);
        billing.subscribe();
        
        uint256 baselineExpiry = billing.getExpiry(subscriber);

        // Warp time forward 15 days (halfway through active window)
        vm.warp(block.timestamp + 15 days);
        billing.renew();
        
        // Assert that the renewal perfectly stacked exactly on top of the original expiry
        assertEq(billing.getExpiry(subscriber), baselineExpiry + period);
        assertTrue(billing.isActive(subscriber));
        vm.stopPrank();
    }

    function test_RenewInsideGraceWindowStacksChronology() public {
        vm.startPrank(subscriber);
        billing.subscribe();
        
        uint256 baselineExpiry = billing.getExpiry(subscriber);

        // Warp time forward 31 days (1 day into the grace period)
        vm.warp(block.timestamp + 31 days);
        
        // Ensure access remains open during grace window
        assertTrue(billing.isActive(subscriber));

        billing.renew();
        
        // Chronological consistency check: must stack from the original expiration, not the warp time
        assertEq(billing.getExpiry(subscriber), baselineExpiry + period);
        vm.stopPrank();
    }

    function test_RenewAfterGraceResetsClock() public {
        vm.startPrank(subscriber);
        billing.subscribe();

        // Warp time forward 35 days (completely past expiration and grace)
        vm.warp(block.timestamp + 35 days);
        
        assertFalse(billing.isActive(subscriber));

        billing.renew();
        
        // Access must reset relative to the current block timestamp execution vector
        assertEq(billing.getExpiry(subscriber), block.timestamp + period);
        assertTrue(billing.isActive(subscriber));
        vm.stopPrank();
    }
}