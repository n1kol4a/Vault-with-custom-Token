//SPDX-License-Identifier:MIT

pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {TimeLockedVault} from "../src/Vault.sol";
import {VaultToken} from "../src/VaultToken.sol";

contract VaultTest is Test {
    TimeLockedVault public vault;
    VaultToken public token;
    address user = makeAddr("user");
    uint256 public constant INITIAL_BALANCE = 1000 ether;

    function setUp() public {
        token = new VaultToken();
        vault = new TimeLockedVault(address(token));

        token.mint(user, INITIAL_BALANCE);

        vm.prank(user);
        token.approve(address(vault), type(uint256).max);
    }

    function testDepositRevertsWhenAmountIsZero() public {
        vm.prank(user);
        vm.expectRevert(TimeLockedVault.TimeLockedVault__FundsAreZero.selector);
        vault.deposit(0);
    }

    function testDeposit() public {
        vm.prank(user);
        vault.deposit(100 ether);
        uint256 expectedBalance = 100 ether;
        vm.prank(user);
        uint256 actualBalance = vault.getUserBalance();

        assertEq(expectedBalance, actualBalance);
    }

    function testLockFundsRevertsWhenFundsAreZero() public {
        vm.startPrank(user);
        vm.expectRevert(TimeLockedVault.TimeLockedVault__CantLockZeroFunds.selector);
        vault.lockFunds(100);
        vm.stopPrank();
    }

    function testLockFundsRevertWhenTimeReduced() public {
        vm.startPrank(user);
        vault.deposit(100 ether);
        vault.lockFunds(1 hours);
        vm.expectRevert(TimeLockedVault.TimeLockedVault__CantLowerLockedTime.selector);
        vault.lockFunds(1 minutes);
        vm.stopPrank();
    }

    function testLockFunds() public {
        vm.startPrank(user);
        vault.deposit(100 ether);
        vault.lockFunds(1 hours);
        vm.stopPrank();
        uint256 expectedTime = 1 hours;
        vm.prank(user);
        uint256 actualTime = vault.getUserLockTime();
        assertApproxEqAbs(expectedTime, actualTime, 1);
    }

    function testWithdrawRevertsWhenNotYetTime() public {
        vm.startPrank(user);
        vault.deposit(100 ether);
        vault.lockFunds(1 hours);
        vm.stopPrank();
        vm.warp(30 minutes);
        vm.prank(user);
        vm.expectRevert(TimeLockedVault.TimeLockedVault__FundsStillLocked.selector);
        vault.withdraw(10 ether);
    }

    function testWithdrawRevertsWhenAmountIsZero() public {
        vm.startPrank(user);
        vault.deposit(100 ether);
        vault.lockFunds(1 hours);
        vm.stopPrank();
        vm.warp(90 minutes);
        vm.prank(user);
        vm.expectRevert(TimeLockedVault.TimeLockedVault__AmountIsZero.selector);
        vault.withdraw(0 ether);
    }

    function testWithdrawRevertsWhenNotEnoughFunds() public {
        vm.startPrank(user);
        vault.deposit(100 ether);
        vault.lockFunds(1 hours);
        vm.stopPrank();
        vm.warp(90 minutes);
        vm.prank(user);
        vm.expectRevert(TimeLockedVault.TimeLockedVault__NotEnoughFunds.selector);
        vault.withdraw(1000 ether);
    }

    function testWithdraw() public {
        vm.startPrank(user);
        vault.deposit(100 ether);
        vault.lockFunds(1 hours);
        vm.stopPrank();
        vm.warp(90 minutes);
        vm.prank(user);
        vault.withdraw(50 ether);
        uint256 expectedFundsAfterWithdrawing = 50 ether;
        vm.prank(user);
        uint256 acutalFundsAfterWithdrawing = vault.getUserBalance();
        assertEq(expectedFundsAfterWithdrawing, acutalFundsAfterWithdrawing);
    }

    function testWithdrawForUserBalance() public {
        vm.startPrank(user);
        vault.deposit(100 ether);
        vault.lockFunds(1 hours);
        vm.stopPrank();
        vm.warp(90 minutes);
        vm.prank(user);
        vault.withdraw(50 ether);
        uint256 expectedFundsAfterWithdrawing = 950 ether;
        vm.prank(user);
        uint256 acutalFundsAfterWithdrawing = token.balanceOf(user);
        assertEq(expectedFundsAfterWithdrawing, acutalFundsAfterWithdrawing);
    }
}
