// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Vault.sol";

contract VaultFactory {
    /// one vault per beneficiary
    mapping(address => address) public vaultOf;

    event VaultCreated(address indexed beneficiary, address vault);

    /// deploy a vault for `beneficiary` (reverts if one already exists)
    function createVault(address beneficiary) external returns (address vault) {
        if (vaultOf[beneficiary] != address(0)) revert VaultExists(beneficiary);
        vault = address(new Vault(beneficiary));
        vaultOf[beneficiary] = vault;
        emit VaultCreated(beneficiary, vault);
    }

    /// true if a vault has been created for `beneficiary`
    function hasVault(address beneficiary) external view returns (bool) {
        return vaultOf[beneficiary] != address(0);
    }

    /// returns the vault; reverts if none exists
    function getVault(address beneficiary) external view returns (address vault) {
        vault = vaultOf[beneficiary];
        if (vault == address(0)) revert NoVaultExists(beneficiary);
    }
}
