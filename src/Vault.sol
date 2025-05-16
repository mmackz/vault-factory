// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "./Errors.sol";

contract Vault is VestingWallet {
    constructor(address beneficiary) payable VestingWallet(beneficiary, uint64(block.timestamp), 0) {}

    function transferOwnership(address) public pure override {
        revert NonTransferable();
    }

    function renounceOwnership() public pure override {
        revert NonTransferable();
    }
}
