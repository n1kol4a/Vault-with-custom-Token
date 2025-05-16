// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TimeLockedVault is ReentrancyGuard {
    error TimeLockedVault__NotOwner();
    error TimeLockedVault__FundsStillLocked();
    error TimeLockedVault__FundsAreZero();
    error TimeLockedVault__TxFailed();
    error TimeLockedVault__NotEnoughFunds();
    error TimeLockedVault__CantLockZeroFunds();
    error TimeLockedVault__CantLowerLockedTime();
    error TimeLockedVault__AmountIsZero();

    event Deposited(address indexed from, uint256 amount);
    event Locked(uint256 unlockTime);
    event Withdrawn(address indexed to, uint256 amount);

    IERC20 public immutable vaultToken;
    mapping(address => uint256) s_userToFunds;
    mapping(address => uint256) s_userToTime;

    constructor(address _token) {
        vaultToken = IERC20(_token);
    }

    /**
     * @notice Deposit token into the vault
     * @param amount amount of token to send to the vault
     */
    function deposit(uint256 amount) external {
        if (amount == 0) revert TimeLockedVault__FundsAreZero();
        bool success = vaultToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TimeLockedVault__TxFailed();
        s_userToFunds[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }
    /**
     * @notice function to lock funds into the vault
     * @param forTime for how long does user want to lock funds
     */

    function lockFunds(uint256 forTime) public {
        if (s_userToFunds[msg.sender] == 0) {
            revert TimeLockedVault__CantLockZeroFunds();
        }
        if (s_userToTime[msg.sender] > block.timestamp + forTime) {
            revert TimeLockedVault__CantLowerLockedTime();
        }
        s_userToTime[msg.sender] = block.timestamp + forTime;
        emit Locked(forTime);
    }
    /**
     * @notice function to withdraw tokens form vault
     * @param _amount amount of tokens user wants to withdraw
     */

    function withdraw(uint256 _amount) public nonReentrant {
        if (s_userToTime[msg.sender] > block.timestamp) {
            revert TimeLockedVault__FundsStillLocked();
        }
        if (_amount == 0) {
            revert TimeLockedVault__AmountIsZero();
        }
        if (s_userToFunds[msg.sender] < _amount) {
            revert TimeLockedVault__NotEnoughFunds();
        }
        emit Withdrawn(msg.sender, _amount);
        s_userToFunds[msg.sender] -= _amount;
        bool success = vaultToken.transfer(msg.sender, _amount);
        if (!success) revert TimeLockedVault__TxFailed();
    }
    /// @notice get user balance

    function getUserBalance() public view returns (uint256) {
        return s_userToFunds[msg.sender];
    }
    /// @notice Get vault balance

    function getBalance() external view returns (uint256) {
        return vaultToken.balanceOf(address(this));
    }

    function getUserLockTime() external view returns (uint256) {
        return s_userToTime[msg.sender];
    }
}
