// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VaultFactory.sol";
import "../src/Vault.sol";
import "./mocks/MockERC20.sol";
import "../src/Errors.sol";

contract VaultFactoryTest is Test {
    VaultFactory factory;
    MockERC20 token;

    address beneficiary = address(0xBEEF);
    address stranger = address(0xCAFE);

    function setUp() public {
        factory = new VaultFactory();
        token = new MockERC20();
        vm.deal(address(this), 10 ether);
    }

    ////////////
    // Deploy //
    ////////////

    function testCreateVault() public {
        address vault = factory.createVault(beneficiary);
        assertEq(factory.vaultOf(beneficiary), vault);
        assertTrue(factory.hasVault(beneficiary));
        assertEq(Vault(payable(vault)).owner(), beneficiary);
    }

    function testDuplicateReverts() public {
        factory.createVault(beneficiary);
        vm.expectRevert(abi.encodeWithSelector(VaultExists.selector, beneficiary));
        factory.createVault(beneficiary);
    }

    function testBeneficiaryIsOwner() public {
        address vault = factory.createVault(beneficiary);
        assertEq(Vault(payable(vault)).owner(), beneficiary);
    }

    function testCreateVaultRevertsForZeroAddressBeneficiary() public {
        vm.expectRevert(InvalidBeneficiary.selector);
        factory.createVault(address(0));
    }

    //////////////
    // ETH flow //
    //////////////

    function testETHDepositAndReleaseByBeneficiary() public {
        address vault = factory.createVault(beneficiary);
        payable(vault).transfer(2 ether);

        vm.prank(beneficiary);
        Vault(payable(vault)).release();

        assertEq(beneficiary.balance, 2 ether);
    }

    function testETHReleaseCallableByAnyone() public {
        address vault = factory.createVault(beneficiary);
        payable(vault).transfer(1 ether);

        vm.prank(stranger);
        Vault(payable(vault)).release();

        assertEq(beneficiary.balance, 1 ether);
    }

    ////////////////
    // Token flow //
    ////////////////

    function testERC20DepositAndReleaseToken() public {
        address vault = factory.createVault(beneficiary);
        token.mint(address(this), 500e18);
        token.transfer(vault, 500e18);

        vm.prank(beneficiary);
        Vault(payable(vault)).release(address(token));

        assertEq(token.balanceOf(beneficiary), 500e18);
    }

    function testERC20DepositAndReleaseETH() public {
        address vault = factory.createVault(beneficiary);
        payable(vault).transfer(2 ether);

        vm.prank(beneficiary);
        Vault(payable(vault)).release();

        assertEq(beneficiary.balance, 2 ether);
    }

    function testERC20ReleaseCallableByAnyone() public {
        address vault = factory.createVault(beneficiary);
        token.mint(address(this), 500e18);
        token.transfer(vault, 500e18);

        vm.prank(stranger);
        Vault(payable(vault)).release(address(token));

        assertEq(token.balanceOf(beneficiary), 500e18);
    }

    //////////
    // Misc //
    //////////

    //--- transferOwnership ---//
    function testTransferOwnershipReverts() public {
        address vault = factory.createVault(beneficiary);

        vm.prank(beneficiary);
        vm.expectRevert(NonTransferable.selector);
        Vault(payable(vault)).transferOwnership(stranger);
    }

    //--- renounceOwnership ---//
    function testRenounceOwnershipReverts() public {
        address vault = factory.createVault(beneficiary);

        vm.prank(beneficiary);
        vm.expectRevert(NonTransferable.selector);
        Vault(payable(vault)).renounceOwnership();
    }

    /////////////
    // Helpers //
    /////////////

    //--- hasVault ---//
    function testHasVaultFalseBeforeCreate() public view {
        assertFalse(factory.hasVault(beneficiary));
    }

    function testHasVaultTrueAfterCreate() public {
        factory.createVault(beneficiary);
        assertTrue(factory.hasVault(beneficiary));
    }

    //--- getVault ---//
    function testGetVaultRevertsWhenNone() public {
        vm.expectRevert(abi.encodeWithSelector(NoVaultExists.selector, beneficiary));
        factory.getVault(beneficiary);
    }

    function testGetVaultReturnsCorrectAddress() public {
        address vault = factory.createVault(beneficiary);
        assertEq(factory.getVault(beneficiary), vault);
    }

    //--- vaultOf ---//
    function testVaultOfZeroAddressWhenNone() public view {
        assertEq(factory.vaultOf(beneficiary), address(0));
    }

    function testVaultOfReturnsCorrectAddress() public {
        address vault = factory.createVault(beneficiary);
        assertEq(factory.vaultOf(beneficiary), vault);
    }

    ////////////////////
    // Implementation //
    ////////////////////

    /// @dev The logic-contract itself must stay locked
    function testImplCannotInitialize() public {
        address implAddr = factory.implementation();
        vm.expectRevert();
        Vault(payable(implAddr)).initialize(beneficiary);
    }

    /// @dev A fresh clone must only initialize once (initializer‐guard)
    function testCloneInitializeOnlyOnce() public {
        address vault = factory.createVault(beneficiary);
        vm.expectRevert();
        Vault(payable(vault)).initialize(beneficiary);
    }
}
