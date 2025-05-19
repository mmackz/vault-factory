// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Vault.sol";
import "./Errors.sol";

contract VaultFactory {
    using Clones for address;

    address public immutable implementation;
    mapping(address => address) public vaultOf;

    event VaultCreated(address indexed beneficiary, address vault);

    constructor() {
        implementation = address(new Vault());
    }

    function createVault(address beneficiary) external returns (address vault) {
        if (beneficiary == address(0)) revert InvalidBeneficiary();
        if (vaultOf[beneficiary] != address(0)) revert VaultExists(beneficiary);

        vault = implementation.clone();
        vaultOf[beneficiary] = vault;
        Vault(payable(vault)).initialize(beneficiary);

        emit VaultCreated(beneficiary, vault);
    }

    function hasVault(address beneficiary) external view returns (bool) {
        return vaultOf[beneficiary] != address(0);
    }

    function getVault(address beneficiary) external view returns (address vault) {
        vault = vaultOf[beneficiary];
        if (vault == address(0)) revert NoVaultExists(beneficiary);
    }
}
