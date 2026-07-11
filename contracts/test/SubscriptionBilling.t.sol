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

    // Multi-tier tracking configurations
    uint256 public constant PLAN_ID = 1;
    uint256 public price = 30 * 10**6; // 30 USDT
    uint32 public period = 30 days;
    uint32 public grace = 3 days;

    function setUp() public {
        // Deploy testing infrastructure
        vm.startPrank(owner);
        usdt = new MockUSDT(1_000_000);
        billing = new SubscriptionBilling(address(usdt));
        
        // Initialize Tier 1 configuration inside setup
        billing.setPlan(PLAN_ID, price, period, grace);
        vm.stopPrank();

        // Distribute tokens and set max allowance permissions
        usdt.mint(subscriber, 1000 * 10**6);
        vm.prank(subscriber);
        usdt.approve(address(billing), type(uint256).max);
    }

    function test_InitialSubscriptionPath() public {
        vm.prank(subscriber);
        billing.subscribe(PLAN_ID);

        assertTrue(billing.isUserActive(subscriber, PLAN_ID));
        assertEq(billing.getExpiry(subscriber, PLAN_ID), block.timestamp + period);
    }

    function test_FailDoubleSubscribeWhileActive() public {
        vm.startPrank(subscriber);
        billing.subscribe(PLAN_ID);
        
        // Assert that a second subscribe to an active plan reverts with custom error
        vm.expectRevert(ISubscriptionBilling.PlanActive.selector);
        billing.subscribe(PLAN_ID);
        vm.stopPrank();
    }

    function test_RenewBeforeExpiryStacksChronology() public {
        vm.startPrank(subscriber);
        billing.subscribe(PLAN_ID);
        
        uint256 baselineExpiry = billing.getExpiry(subscriber, PLAN_ID);

        // Warp time forward 15 days (halfway through active cycle)
        vm.warp(block.timestamp + 15 days);
        billing.renew(PLAN_ID);
        
        // Expiry must stack perfectly from the previous expiration date
        assertEq(billing.getExpiry(subscriber, PLAN_ID), baselineExpiry + period);
        assertTrue(billing.isUserActive(subscriber, PLAN_ID));
        vm.stopPrank();
    }

    function test_RenewInsideGraceWindowStacksChronology() public {
        vm.startPrank(subscriber);
        billing.subscribe(PLAN_ID);
        
        uint256 baselineExpiry = billing.getExpiry(subscriber, PLAN_ID);

        // Warp time forward 31 days (1 day past expiry, inside the 3-day grace window)
        vm.warp(block.timestamp + 31 days);
        
        assertTrue(billing.isUserActive(subscriber, PLAN_ID));

        billing.renew(PLAN_ID);
        
        // Check that chronological continuity is preserved inside the grace tier
        assertEq(billing.getExpiry(subscriber, PLAN_ID), baselineExpiry + period);
        vm.stopPrank();
    }

    function test_RenewAfterGraceResetsClock() public {
        vm.startPrank(subscriber);
        billing.subscribe(PLAN_ID);

        // Warp time forward 35 days (completely expired outside the grace window)
        vm.warp(block.timestamp + 35 days);
        
        assertFalse(billing.isUserActive(subscriber, PLAN_ID));

        billing.renew(PLAN_ID);
        
        // Expiry must reset relative to the block timestamp of the new transaction execution
        assertEq(billing.getExpiry(subscriber, PLAN_ID), block.timestamp + period);
        assertTrue(billing.isUserActive(subscriber, PLAN_ID));
        vm.stopPrank();
    }

    function test_GraceBoundaryIsInclusiveAtFinalSecond() public {
        vm.startPrank(subscriber);
        billing.subscribe(PLAN_ID);

        uint256 baselineExpiry = billing.getExpiry(subscriber, PLAN_ID);
        vm.warp(baselineExpiry + grace);

        assertTrue(billing.isUserActive(subscriber, PLAN_ID));

        billing.renew(PLAN_ID);

        assertEq(billing.getExpiry(subscriber, PLAN_ID), baselineExpiry + period);
        vm.stopPrank();
    }

    function test_TogglePlanStatusPausesAndRestoresTier() public {
        vm.startPrank(owner);
        billing.togglePlanStatus(PLAN_ID, false);
        vm.stopPrank();

        vm.prank(subscriber);
        vm.expectRevert(ISubscriptionBilling.PlanNotActive.selector);
        billing.subscribe(PLAN_ID);

        vm.startPrank(owner);
        billing.togglePlanStatus(PLAN_ID, true);
        vm.stopPrank();

        vm.prank(subscriber);
        billing.subscribe(PLAN_ID);

        assertTrue(billing.isUserActive(subscriber, PLAN_ID));
    }
}