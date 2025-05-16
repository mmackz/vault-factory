# Vault-Factory

## Overview

Vault-Factory is a Solidity project that provides a factory for deploying simple, soulbound vault contracts. Each vault is a modified version of OpenZeppelin's `VestingWallet.sol`, with the vesting logic effectively removed by setting the duration to zero and the start time to the deployment block. This turns them into basic vaults from which funds (ETH or ERC20 tokens) can be withdrawn at any time by the beneficiary.

A key feature is that the ownership transfer and renouncement functions in the vaults are disabled, making each vault permanently tied (soulbound) to its beneficiary's address. The factory ensures that only one vault can be created per beneficiary address.

The project uses Foundry for development, testing, and deployment.

## Features

*   **Simple Vaults:** Deploys vaults that allow beneficiaries to withdraw ETH or ERC20 tokens at any time.
*   **Soulbound:** Vaults cannot be transferred or have their ownership renounced, permanently linking them to the beneficiary.
*   **Factory Contract:** Manages the creation of vaults, ensuring only one vault per beneficiary.
*   **Utility Functions:**
    *   `createVault(address beneficiary)`: Deploys a new vault for the specified beneficiary.
    *   `hasVault(address beneficiary)`: Checks if a vault exists for a beneficiary.
    *   `getVault(address beneficiary)`: Retrieves the address of the vault for a beneficiary.
    *   `vaultOf[beneficiary]`: Public mapping to directly look up a beneficiary's vault.
*   **Based on OpenZeppelin:** Core vault logic leverages the battle-tested `VestingWallet.sol`.

## Contracts

*   `VaultFactory.sol`: The factory contract responsible for deploying and managing `Vault` instances.
*   `Vault.sol`: The individual vault contract. Inherits from OpenZeppelin's `VestingWallet` and includes modifications for immediate fund release and disabled ownership transfers.
*   `Errors.sol`: Custom error definitions used by the contracts.

## Getting Started

### Prerequisites

*   [Foundry](https://getfoundry.sh/) installed.

### Environment Variables

Create a `.env` file in the root of the project with the following variables:

```env
PRIVATE_KEY=<YOUR_PRIVATE_KEY>
# Optional: Address of a beneficiary to create a vault for upon factory deployment
BENEFICIARY=<YOUR_BENEFICIARY_ADDRESS>
ETHERSCAN_API_KEY=<YOUR_ETHERSCAN_API_KEY>
RPC_URL=<YOUR_RPC_URL>
```

*   `PRIVATE_KEY`: Required for deploying contracts.
*   `BENEFICIARY`: (Optional) If provided, a vault for this address can be created during the factory deployment script.
*   `ETHERSCAN_API_KEY`: Required for verifying contracts on Etherscan.
*   `RPC_URL`: The URL for the Ethereum node to interact with (e.g., Infura, Alchemy).

### Installation

Clone the repository and install dependencies:

```bash
git clone <repository-url>
cd vault-factory
forge install
```

### Compilation

Compile the contracts:

```bash
forge build
```

### Testing

Run the test suite:

```bash
forge test
```

### Deployment

Deployment scripts are typically located in the `script/` directory. To deploy the `VaultFactory` (and optionally an initial vault if `BENEFICIARY` is set in your `.env`), you would run a script similar to this:

```bash
forge script script/DeployFactory.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify -vvvv
```

*(Note: Adjust the script name `DeployFactory.s.sol` if it's different in your project.)*

## Usage

### Creating a Vault

After deploying the `VaultFactory`, anyone can create a new vault for a specific beneficiary by calling the `createVault(address beneficiary)` function on the factory.

```solidity
// Example interaction
address beneficiary = 0x...;
address vaultAddress = vaultFactory.createVault(beneficiary);
```

### Interacting with a Vault

Once a vault is created, the beneficiary (or anyone, for release functions) can interact with it.

*   **Depositing ETH:** Send ETH directly to the vault address.
*   **Depositing ERC20 Tokens:** Transfer ERC20 tokens to the vault address.
*   **Releasing ETH:**
    ```solidity
    // Called by beneficiary or anyone
    Vault(payable(vaultAddress)).release();
    ```
*   **Releasing ERC20 Tokens:**
    ```solidity
    // Called by beneficiary or anyone
    IERC20 token = IERC20(tokenAddress);
    Vault(payable(vaultAddress)).release(address(token));
    ```

## Contributing

Contributions are welcome! Please follow standard Solidity best practices and ensure all tests pass before submitting a pull request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
