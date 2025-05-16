// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VaultFactory.sol";

/// @notice Broadcasts a VaultFactory deployment
contract DeployFactory is Script {
    /// Set these in your shell before running:
    ///   export PRIVATE_KEY=0x...
    ///   export RPC_URL=https://sepolia.base.org            # or mainnet URL
    ///   # OPTIONAL – deploy an initial vault in same tx
    ///   export BENEFICIARY=0xYourEoa
    function run() external {
        uint256 pk          = vm.envUint("PRIVATE_KEY");
        address beneficiary = vm.envOr("BENEFICIARY", address(0));

        vm.startBroadcast(pk);

        // 1. deploy factory
        VaultFactory factory = new VaultFactory();

        // 2. optionally create the first vault
        if (beneficiary != address(0)) {
            factory.createVault(beneficiary);
        }

        vm.stopBroadcast();
    }
}
