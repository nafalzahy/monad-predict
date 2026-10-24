// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MonadPredict} from "../src/MonadPredict.sol";

contract MonadPredictTest is Test {
    MonadPredict pm;
    address creator = makeAddr("creator");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        pm = new MonadPredict();
        vm.deal(creator, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.prank(creator);
        pm.createMarket{value: 1 ether}("Apakah BTC tembus 150k?", "Tes", "Crypto", "B", uint64(block.timestamp + 1 days));
    }

    function test_InitialPrice() public view {
        assertEq(pm.marketCount(), 1);
        assertEq(uint256(pm.getMarkets(0, 10)[0].yesReserve), 1 ether);
    }

    function test_BuyYesRaisesPrice() public {
        vm.prank(alice);
        pm.buy{value: 1 ether}(0, true, 0);
        assertGt(pm.yesShares(0, alice), 0.9 ether);
        MonadPredict.Trade memory t = pm.getTrades(0, 0, 1)[0];
        assertGt(t.yesPriceBps, 5000);
    }

    function test_SellBackLosesOnlyFees() public {
        uint256 before = alice.balance;
        vm.startPrank(alice);
        pm.buy{value: 1 ether}(0, true, 0);
        pm.sell(0, true, pm.yesShares(0, alice), 0);
        vm.stopPrank();
        assertLt(alice.balance, before);
        assertGt(alice.balance, before - 0.05 ether);
    }

    function test_ResolveRedeemAndSolvency() public {
        vm.prank(alice);
        pm.buy{value: 1 ether}(0, true, 0);
        vm.prank(bob);
        pm.buy{value: 1 ether}(0, false, 0);

        vm.expectRevert();
        vm.prank(creator);
        pm.resolve(0, true); // belum waktunya

        vm.warp(block.timestamp + 1 days + 1);
        vm.prank(creator);
        pm.resolve(0, true);

        uint256 shares = pm.yesShares(0, alice);
        uint256 b = alice.balance;
        vm.prank(alice);
        pm.redeem(0);
        assertEq(alice.balance - b, shares);

        vm.expectRevert();
        vm.prank(bob);
        pm.redeem(0);

        vm.prank(creator);
        pm.claimCreator(0);
        assertEq(address(pm).balance, 0); // semua dana terbagi habis
    }

    function test_CannotTradeAfterClose() public {
        vm.warp(block.timestamp + 1 days + 1);
        vm.expectRevert();
        vm.prank(alice);
        pm.buy{value: 1 ether}(0, true, 0);
    }
}