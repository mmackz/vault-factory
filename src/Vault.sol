// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-upgradeable/contracts/finance/VestingWalletUpgradeable.sol";
import "./Errors.sol";

/**
 * @title Vault
 * @notice A non-transferable wallet based on VestingWalletUpgradeable with vesting logic removed
 * @dev Extends VestingWalletUpgradeable but sets duration to 0, making all funds immediately available
 *      Ownership transfer and renouncement are permanently blocked to ensure non-transferability
 *      Only one vault per user is enforced by the VaultFactory
 */
contract Vault is VestingWalletUpgradeable {
    /**
     * @notice Disables initializers to prevent direct initialization of the implementation
     * @dev Required for upgradeable contracts to prevent implementation initialization
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the vault for a specific beneficiary with no vesting period
     * @dev Sets start time to current block timestamp and duration to 0, removing vesting logic
     *      This makes all deposited funds immediately available to the beneficiary
     *      Will revert if called more than once due to initializer modifier
     * @param beneficiary The address that will own this vault and receive all funds
     */
    function initialize(address beneficiary) external initializer {
        __VestingWallet_init(beneficiary, uint64(block.timestamp), 0);
    }

    /**
     * @notice Permanently blocks ownership transfer to ensure vault non-transferability
     * @dev Always reverts with NonTransferable error, making vaults permanently bound to their beneficiary
     */
    function transferOwnership(address) public pure override {
        revert NonTransferable();
    }

    /**
     * @notice Permanently blocks ownership renouncement to ensure vault non-transferability
     * @dev Always reverts with NonTransferable error, preventing vaults from becoming ownerless
     */
    function renounceOwnership() public pure override {
        revert NonTransferable();
    }
}
