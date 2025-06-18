// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "script/DeployOurToken.s.sol";
import {OurToken} from "src/OurToken.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(address(this), 1);
    }

    function testBalance() public view {
        assertEq(ourToken.balanceOf(alice), 0);
    }

    function testBobBalance() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testTransferInsufficientBalance() public {
        uint256 transferAmount = STARTING_BALANCE + 1;

        vm.prank(alice);
        vm.expectRevert();
        ourToken.transfer(bob, transferAmount);
    }

    function testTransferFromInsufficientAllowance() public {
        uint256 approveAmount = 1000;
        uint256 transferAmount = approveAmount + 1;

        vm.prank(alice);
        ourToken.approve(bob, approveAmount);

        vm.prank(bob);
        vm.expectRevert();
        ourToken.transferFrom(alice, bob, transferAmount);
    }

    function testTransferFromInsufficientBalance() public {
        uint256 approveAmount = STARTING_BALANCE + 1;
        uint256 transferAmount = STARTING_BALANCE + 1;

        vm.prank(alice);
        ourToken.approve(bob, approveAmount);

        vm.prank(bob);
        vm.expectRevert();
        ourToken.transferFrom(alice, bob, transferAmount);
    }

    function testTransferToZeroAddress() public {
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transfer(address(0), 100);
    }

    function testTransferFromToZeroAddress() public {
        uint256 approveAmount = 1000;

        vm.prank(alice);
        ourToken.approve(bob, approveAmount);

        vm.prank(bob);
        vm.expectRevert();
        ourToken.transferFrom(alice, address(0), 100);
    }

    function testApprove() public {
        uint256 approveAmount = 1000;

        vm.prank(alice);
        bool success = ourToken.approve(bob, approveAmount);

        assertTrue(success);
        assertEq(ourToken.allowance(alice, bob), approveAmount);
    }

    function testMetadata() public view {
        assertEq(ourToken.name(), "OurToken");
        assertEq(ourToken.symbol(), "OT");
        assertEq(ourToken.decimals(), 18);
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000;

        uint256 transferAmount = 500;

        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }
}
