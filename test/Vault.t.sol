// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VaultFactory.sol";
import "../src/Vault.sol";
import "./mocks/MockERC20.sol";
import "../src/Errors.sol";

contract VaultTest is Test {
    VaultFactory factory;
    MockERC20 token;
    address beneficiary = address(0xBEEF);
    address _vault;

    function setUp() public {
        factory = new VaultFactory();
        token = new MockERC20();
        vm.deal(address(this), 10 ether);
        _vault = factory.createVault(beneficiary);
    }

    /// @dev Vesting parameters should be start == deployment block timestamp and duration == 0
    function testVestingParameters() public view {
        Vault vault = Vault(payable(_vault));
        uint256 startTime = vault.start();
        uint256 duration = vault.duration();
        // duration must be zero
        assertEq(duration, 0);
        // startTime is set at creation => equals block.timestamp
        assertEq(startTime, uint64(block.timestamp));
    }

    /// @dev ETH releasable and released fields should track deposits correctly
    function testEthReleasableAndReleased() public {
        Vault vault = Vault(payable(_vault));

        // no funds yet
        assertEq(vault.releasable(), 0);
        assertEq(vault.released(), 0);

        // deposit ETH
        payable(vault).transfer(1 ether);
        // after deposit, releasable should equal deposited amount
        assertEq(vault.releasable(), 1 ether);
        assertEq(vault.released(), 0);

        // release by beneficiary
        vm.prank(beneficiary);
        vault.release();

        // after release, released == deposit, releasable == 0
        assertEq(vault.released(), 1 ether);
        assertEq(vault.releasable(), 0);
    }

    /// @dev ERC20 releasable and released fields should track deposits correctly
    function testERC20ReleasableAndReleased() public {
        Vault vault = Vault(payable(_vault));

        // no tokens yet
        assertEq(vault.releasable(address(token)), 0);
        assertEq(vault.released(address(token)), 0);

        // deposit ERC20
        token.mint(address(this), 500e18);
        token.transfer(address(vault), 500e18);
        // after deposit, releasable should equal deposited amount
        assertEq(vault.releasable(address(token)), 500e18);
        assertEq(vault.released(address(token)), 0);

        // release by beneficiary
        vm.prank(beneficiary);
        vault.release(address(token));

        // after release, released == deposit, releasable == 0
        assertEq(vault.released(address(token)), 500e18);
        assertEq(vault.releasable(address(token)), 0);
    }

    /// @dev Test releasing ETH when vault balance is zero
    function testReleaseEthWithNoFunds() public {
        Vault vault = Vault(payable(_vault));
        uint256 initialBeneficiaryBalance = beneficiary.balance;

        // Ensure vault has no ETH for this test
        assertEq(address(_vault).balance, 0);
        assertEq(vault.releasable(), 0);
        assertEq(vault.released(), 0);

        // Attempt to release ETH
        vm.prank(beneficiary);
        vault.release();

        // Balances and vault state should remain unchanged
        assertEq(beneficiary.balance, initialBeneficiaryBalance);
        assertEq(vault.releasable(), 0);
        assertEq(vault.released(), 0);
        assertEq(address(_vault).balance, 0);
    }

    /// @dev Test releasing ERC20 when vault balance is zero for that token
    function testReleaseERC20WithNoFunds() public {
        Vault vault = Vault(payable(_vault));
        MockERC20 otherToken = new MockERC20();
        uint256 initialBeneficiaryTokenBalance = token.balanceOf(beneficiary);
        uint256 initialBeneficiaryOtherTokenBalance = otherToken.balanceOf(beneficiary);

        // Ensure vault has no specific tokens for this test
        assertEq(token.balanceOf(_vault), 0);
        assertEq(otherToken.balanceOf(_vault), 0);
        assertEq(vault.releasable(address(token)), 0);
        assertEq(vault.released(address(token)), 0);
        assertEq(vault.releasable(address(otherToken)), 0);
        assertEq(vault.released(address(otherToken)), 0);

        // Attempt to release MOCK token
        vm.prank(beneficiary);
        vault.release(address(token));

        // Attempt to release otherToken
        vm.prank(beneficiary);
        vault.release(address(otherToken));

        // Balances and vault state should remain unchanged
        assertEq(token.balanceOf(beneficiary), initialBeneficiaryTokenBalance);
        assertEq(vault.releasable(address(token)), 0);
        assertEq(vault.released(address(token)), 0);
        assertEq(token.balanceOf(_vault), 0);
        assertEq(otherToken.balanceOf(beneficiary), initialBeneficiaryOtherTokenBalance);
        assertEq(vault.releasable(address(otherToken)), 0);
        assertEq(vault.released(address(otherToken)), 0);
        assertEq(otherToken.balanceOf(_vault), 0);
    }
}
