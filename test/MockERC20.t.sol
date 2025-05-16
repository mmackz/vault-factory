// test/MockERC20.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./mocks/MockERC20.sol";

contract MockERC20Test is Test {
    MockERC20 token;
    address   user = address(0xBEEF);

    function setUp() public {
        token = new MockERC20();
    }

    ///////////////
    // Metadata //
    ///////////////

    function testName() public view {
        assertEq(token.name(), "Mock ERC20");
    }

    function testSymbol() public view {
        assertEq(token.symbol(), "MOCK");
    }

    function testDecimals() public view {
        assertEq(token.decimals(), 18);
    }

    ///////////////////
    // Supply & Mint //
    ///////////////////

    function testInitialSupplyZero() public view {
        assertEq(token.totalSupply(), 0);
    }

    function testMint() public {
        token.mint(user, 100e18);
        assertEq(token.totalSupply(), 100e18);
        assertEq(token.balanceOf(user), 100e18);
    }

    function testMintPayableSuccess() public {
        vm.deal(address(this), 1 ether);
        token.mintPayable{value: 1 ether}(user, 1e20); // needs ≥ amount/100
        assertEq(token.balanceOf(user), 1e20);
    }

    function testMintPayableInsufficientValueReverts() public {
        vm.expectRevert("MockERC20: gimme more money!");
        token.mintPayable{value: 1 wei}(user, 1e20);   // far less than amount/100
    }
}
