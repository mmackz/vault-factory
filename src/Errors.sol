// src/Errors.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error NonTransferable();
error CannotRenounce();
error VaultExists(address beneficiary);
error NoVaultExists(address beneficiary);
