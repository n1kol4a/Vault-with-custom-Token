// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {VaultTokenMinter} from "./VaultTokenMinter.sol";

contract TimeLockedVault is ReentrancyGuard {
    error TimeLockedVault__NotOwner();
    error TimeLockedVault__FundsStillLocked();
    error TimeLockedVault__FundsAreZero();
    error TimeLockedVault__TxFailed();
    error TimeLockedVault__NotEnoughFunds();
    error TimeLockedVault__CantLockZeroFunds();
    error TimeLockedVault__CantLowerLockedTime();
    error TimeLockedVault__AmountIsZero();
    error TimeLockedVault__InterestRateNeedsToBeUpdatedBeforeWithdrawn();
    error TimeLockedVault__HaventLockedFundsYet();

    event Deposited(address indexed from, uint256 amount);
    event Locked(uint256 unlockTime);
    event Withdrawn(address indexed to, uint256 amount);

    VaultTokenMinter public minter;
    IERC20 public immutable vaultToken;
    mapping(address => uint256) s_userToFunds;
    mapping(address => uint256) s_userToTime;
    mapping(address => uint256) public lastUpdateTime;
    uint256 public constant INTEREST_RATE_PER_SECOND = 1585489599; //5% annual, 1e18 scale
    uint256 public constant INTEREST_UPDATE_THRESHOLD = 1 hours;

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
        if (lastUpdateTime[msg.sender] == 0) {
            lastUpdateTime[msg.sender] = block.timestamp;
        }
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
        if (block.timestamp - lastUpdateTime[msg.sender] > INTEREST_UPDATE_THRESHOLD) {
            revert TimeLockedVault__InterestRateNeedsToBeUpdatedBeforeWithdrawn();
        }
        emit Withdrawn(msg.sender, _amount);
        s_userToFunds[msg.sender] -= _amount;
        bool success = vaultToken.transfer(msg.sender, _amount);
        if (!success) revert TimeLockedVault__TxFailed();
    }
    ///@notice updates interest rate for the user

    function updateInterest() public {
        _updateInterest(msg.sender);
    }
    /**
     * @notice updates interest rate for the user
     * @param user user to update interest rate for
     */

    function _updateInterest(address user) internal {
        if (s_userToTime[user] == 0) {
            revert TimeLockedVault__HaventLockedFundsYet();
        }
        uint256 last = lastUpdateTime[user];

        uint256 timeElapsed = block.timestamp - last;
        uint256 principal = s_userToFunds[user];

        if (principal == 0 || timeElapsed == 0) return;

        uint256 interest = (principal * INTEREST_RATE_PER_SECOND * timeElapsed) / 1e18;
        s_userToFunds[user] += interest;
        lastUpdateTime[user] = block.timestamp;
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
