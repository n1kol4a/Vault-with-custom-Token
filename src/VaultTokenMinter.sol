// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {VaultToken} from "./VaultToken.sol";

contract VaultTokenMinter {
    VaultToken public immutable token;

    error VaultTokenMinter__SendMoreEth();
    error VaultTokenMinter__TxFailed();
    error VaultTokenMinter__NotEnoughEthInReserve();

    constructor(address _token) {
        token = VaultToken(_token);
    }

    /// @notice Mint VaultTokens by sending ETH
    function mint() external payable {
        if (msg.value == 0) {
            revert VaultTokenMinter__SendMoreEth();
        }
        token.mint(msg.sender, msg.value); // 1:1 ETH to VaultToken
    }

    /**
     * @notice Burn VaultTokens to get ETH back
     * @param amount amount of tokens to burn
     */
    function burn(uint256 amount) external {
        if (address(this).balance <= amount) {
            revert VaultTokenMinter__NotEnoughEthInReserve();
        }
        token.burn(msg.sender, amount);
        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) {
            revert VaultTokenMinter__TxFailed();
        }
    }

    /// @notice Allow contract to receive ETH
    receive() external payable {}
}
