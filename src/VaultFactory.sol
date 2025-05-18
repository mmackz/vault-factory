// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./VaultImpl.sol";
import "./Errors.sol";

contract VaultFactory {
    using Clones for address;

    address public immutable implementation;
    mapping(address => address) public vaultOf;

    event VaultCreated(address indexed beneficiary, address vault);

    constructor() {
        implementation = address(new VaultImpl());
    }

    function createVault(address beneficiary) external returns (address vault) {
        if (vaultOf[beneficiary] != address(0)) revert VaultExists(beneficiary);

        vault = implementation.clone();
        VaultImpl(payable(vault)).initialize(beneficiary);

        vaultOf[beneficiary] = vault;
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
