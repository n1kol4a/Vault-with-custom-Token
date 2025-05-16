//SPDX-License-Identifier:MIT

pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {TimeLockedVault} from "../src/Vault.sol";
import {VaultToken} from "../src/VaultToken.sol";
import {VaultTokenMinter} from "../src/VaultTokenMinter.sol";

contract Integration is Test {
    TimeLockedVault public vault;
    VaultToken public token;
    address user = makeAddr("user");
    uint256 public constant INITIAL_BALANCE = 1000 ether;
    VaultTokenMinter minter;

    function setUp() public {
        token = new VaultToken();
        vault = new TimeLockedVault(address(token));
        minter = new VaultTokenMinter(address(token));

        vm.deal(user, INITIAL_BALANCE);
        vm.prank(user);
        token.approve(address(vault), type(uint256).max);
        token.transferOwnership(address(minter));
    }

    function testFullFlow() public {
        vm.startPrank(user);

        // Mint tokens by sending ETH to minter
        minter.mint{value: 1 ether}(); // 1 token

        // Deposit into vault
        vault.deposit(1e18);

        // Lock funds for 10 seconds
        vault.lockFunds(10);

        // Fast-forward time
        vm.warp(block.timestamp + 11);

        // Withdraw
        vault.withdraw(1e18);

        vm.stopPrank();
    }
}
