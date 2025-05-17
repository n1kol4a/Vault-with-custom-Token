//SPDX-License-Identifier:MIT

pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {TimeLockedVault} from "../src/Vault.sol";
import {VaultToken} from "../src/VaultToken.sol";
import {VaultTokenMinter} from "../src/VaultTokenMinter.sol";

contract MinterTest is Test {
    VaultToken public token;
    VaultTokenMinter public minter;
    address user = makeAddr("user");
    uint256 public constant INITIAL_BALANCE = 1000 ether;

    function setUp() public {
        token = new VaultToken();
        minter = new VaultTokenMinter(address(token));
        token.transferOwnership(address(minter));

        vm.deal(user, INITIAL_BALANCE);
        vm.prank(user);
        token.approve(user, INITIAL_BALANCE);
    }

    modifier minted() {
        vm.prank(user);
        minter.mint{value: 500 ether}();
        _;
    }

    function testMint() public {
        vm.prank(user);
        minter.mint{value: 500 ether}();
        uint256 mintedValue = token.balanceOf(user);
        assertEq(mintedValue, 500 ether);
    }

    function testBurn() public minted {
        vm.prank(user);
        minter.burn(350 ether);
        uint256 leftoverBalnce = token.balanceOf(user);
        assertEq(leftoverBalnce, 150 ether);
    }

    function testBurnGivesBackEth() public minted {
        vm.prank(user);
        minter.burn(350 ether);
        uint256 userEthBalance = address(user).balance;
        assertEq(userEthBalance, 850 ether);
    }

    function testCantMintZeroValue() public {
        vm.prank(user);
        vm.expectRevert(VaultTokenMinter.VaultTokenMinter__SendMoreEth.selector);
        minter.mint{value: 0 ether}();
    }

    function testCantBurnOverTheLimit() public minted {
        vm.prank(user);
        vm.expectRevert(VaultTokenMinter.VaultTokenMinter__NotEnoughEthInReserve.selector);
        minter.burn(10000 ether);
    }
}
