//SPDX-License-Identifier:MIT

pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {TimeLockedVault} from "../src/Vault.sol";
import {VaultToken} from "../src/VaultToken.sol";
import {VaultTokenMinter} from "../src/VaultTokenMinter.sol";

contract DeployVault is Script {
    TimeLockedVault public vault;
    VaultToken public token;
    VaultTokenMinter public minter;

    function run() public {
        vm.startBroadcast();
        token = new VaultToken();
        minter = new VaultTokenMinter(address(token));
        token.transferOwnership(address(minter));
        vault = new TimeLockedVault(address(token));
        vm.stopBroadcast();
    }
}
