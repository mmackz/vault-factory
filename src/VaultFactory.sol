// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Vault.sol";
import "./Errors.sol";

/**
 * @title VaultFactory
 * @notice A factory contract for creating minimal proxy clones of Vault contracts
 * @dev Uses OpenZeppelin's Clones library for deterministic deployments
 */
contract VaultFactory {
    using Clones for address;

    /// @notice The implementation contract address used for all vault clones
    address public immutable implementation;
    
    /// @notice Mapping of beneficiary addresses to their deployed vault addresses
    /// @dev Only contains entries for deployed vaults
    mapping(address => address) public deployedVault;

    /// @notice Emitted when a new vault is created
    /// @param beneficiary The address that will own the vault
    /// @param vault The address of the newly created vault
    event VaultCreated(address indexed beneficiary, address vault);

    /**
     * @notice Deploys the implementation contract and stores its address
     * @dev The implementation is deployed once and used for all clones
     */
    constructor() {
        implementation = address(new Vault());
    }

    /**
     * @notice Creates a vault for the beneficiary at the predetermined address
     * @dev Uses CREATE2 through cloneDeterministic for deterministic addresses
     * @param beneficiary The address that will own the vault (cannot be zero address)
     * @return vault The address of the newly created vault
     * @custom:throws InvalidBeneficiary if beneficiary is the zero address
     * @custom:throws VaultExists if a vault already exists for this beneficiary
     */
    function createVault(address beneficiary) external returns (address vault) {
        if (beneficiary == address(0)) revert InvalidBeneficiary();
        if (deployedVault[beneficiary] != address(0)) revert VaultExists(beneficiary);

        bytes32 salt = keccak256(abi.encodePacked(beneficiary));
        vault = implementation.cloneDeterministic(salt);
        deployedVault[beneficiary] = vault;
        Vault(payable(vault)).initialize(beneficiary);

        emit VaultCreated(beneficiary, vault);
    }

    /**
     * @notice Checks if a vault has been deployed for a beneficiary address
     * @dev Returns true only if createVault() has been called for this beneficiary
     * @param beneficiary The address to check for an existing vault
     * @return bool True if a vault has been deployed, false otherwise
     */
    function hasDeployedVault(address beneficiary) external view returns (bool) {
        return deployedVault[beneficiary] != address(0);
    }

    /**
     * @notice Gets the predetermined address for a beneficiary whether they have deployed a vault there or not
     * @dev Uses predictDeterministicAddress to calculate the address that would be used by createVault()
     * @param beneficiary The address to get the vault address for
     * @return vault The predetermined address where the vault would be (or is) deployed
     */
    function getVaultAddress(address beneficiary) external view returns (address vault) {
        bytes32 salt = keccak256(abi.encodePacked(beneficiary));
        return implementation.predictDeterministicAddress(salt);
    }
}
