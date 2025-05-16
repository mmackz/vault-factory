// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MockERC20
/// @notice A mock ERC-20 token
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock ERC20", "MOCK") {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function mintPayable(address to, uint256 amount) public payable {
        require(msg.value >= amount / 100, "MockERC20: gimme more money!");
        _mint(to, amount);
    }
}
