// src/Errors.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error InvalidBeneficiary();
error NonTransferable();
error NoVaultExists(address beneficiary);
error VaultExists(address beneficiary);
