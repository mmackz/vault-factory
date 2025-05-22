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
        assertEq(factory.deployedVault(beneficiary), vault);
        assertTrue(factory.hasDeployedVault(beneficiary));
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

    //--- hasDeployedVault ---//
    function testHasDeployedVaultFalseBeforeCreate() public view {
        assertFalse(factory.hasDeployedVault(beneficiary));
    }

    function testHasDeployedVaultTrueAfterCreate() public {
        factory.createVault(beneficiary);
        assertTrue(factory.hasDeployedVault(beneficiary));
    }

    //--- deployedVault ---//
    function testDeployedVaultZeroAddressWhenNone() public view {
        assertEq(factory.deployedVault(beneficiary), address(0));
    }

    function testDeployedVaultReturnsCorrectAddress() public {
        address vault = factory.createVault(beneficiary);
        assertEq(factory.deployedVault(beneficiary), vault);
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

    /////////////////////////////////
    // Deterministic Address Tests //
    /////////////////////////////////

    function testDeterministicAddressUniqueness() public {
        address beneficiary1 = address(0xBEEF);
        address beneficiary2 = address(0xFACE);

        address vault1 = factory.createVault(beneficiary1);
        address vault2 = factory.createVault(beneficiary2);

        assertEq(factory.deployedVault(beneficiary1), vault1);
        assertEq(factory.deployedVault(beneficiary2), vault2);
        assertNotEq(vault1, vault2);
    }

    function testDeterministicAddressMatchesComputedCreate2Address() public {
        address implementation = factory.implementation();
        address benefactor = address(0x865C301c46d64DE5c9B124Ec1a97eF1EFC1bcbd1);

        bytes32 salt = keccak256(abi.encodePacked(benefactor));

        // The proxy creation code for Clones.cloneDeterministic is:
        // 0x3d602d80600a3d3981f3363d3d373d3d3d363d73[IMPLEMENTATION_ADDRESS]5af43d82803e903d91602b57fd5bf3
        // Where [IMPLEMENTATION_ADDRESS] is the 20-byte address of the implementation contract.
        bytes memory proxyBytecode = abi.encodePacked(
            bytes10(0x3d602d80600a3d3981f3),
            bytes10(0x363d3d373d3d3d363d73),
            implementation,
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );
        bytes32 proxyBytecodeHash = keccak256(proxyBytecode);

        address expectedVaultAddress = vm.computeCreate2Address(salt, proxyBytecodeHash, address(factory));

        address actualVaultAddress = factory.createVault(benefactor);

        assertEq(actualVaultAddress, expectedVaultAddress);
        assertEq(factory.deployedVault(benefactor), expectedVaultAddress);
    }

    function testDeterministicAddressSaltUniqueness() public {
        address beneficiary1 = address(0x1111);
        address beneficiary2 = address(0x2222);

        bytes32 salt1 = keccak256(abi.encodePacked(beneficiary1));
        bytes32 salt2 = keccak256(abi.encodePacked(beneficiary2));

        assertNotEq(salt1, salt2);

        // Create vaults to ensure different salts lead to different addresses
        address vault1 = factory.createVault(beneficiary1);
        address vault2 = factory.createVault(beneficiary2);
        assertNotEq(vault1, vault2);
    }
}
