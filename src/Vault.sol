// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-upgradeable/contracts/finance/VestingWalletUpgradeable.sol";
import "./Errors.sol";

contract Vault is VestingWalletUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function initialize(address beneficiary) external initializer {
        __VestingWallet_init(beneficiary, uint64(block.timestamp), 0);
    }

    function transferOwnership(address) public pure override {
        revert NonTransferable();
    }

    function renounceOwnership() public pure override {
        revert NonTransferable();
    }
}
