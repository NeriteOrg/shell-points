// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ShellToken.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract ShellTokenTest is Test {
    ShellToken internal shellToken;
    address internal admin = makeAddr("admin");
    address internal owner = makeAddr("owner");

    function setUp() public {
        vm.startPrank(owner);
        shellToken = new ShellToken();
        shellToken.updateIsAdmin(admin, true);
        vm.stopPrank();
    }

    function test_updateIsAdmin() public {
        address tempAdmin = makeAddr("tempAdmin");

        assertEq(shellToken.isAdmin(tempAdmin), false);

        vm.prank(owner);
        shellToken.updateIsAdmin(tempAdmin, true);

        assertEq(shellToken.isAdmin(tempAdmin), true);

        vm.prank(owner);
        shellToken.updateIsAdmin(tempAdmin, false);

        assertEq(shellToken.isAdmin(tempAdmin), false);
    }

    function test_mintShells() public {
        address user = makeAddr("user");

        vm.startPrank(admin);
        shellToken.mintShells(user, 100);
        vm.stopPrank();

        assertEq(shellToken.balanceOf(user), 100);
    }

    function test_revert_mintShells_notAdmin() public {
        address user = makeAddr("user");

        vm.startPrank(makeAddr("notAdmin"));
        vm.expectRevert("Not an admin");
        shellToken.mintShells(user, 100);
        vm.stopPrank();

        assertEq(shellToken.balanceOf(user), 0);
    }

    function test_mintBatchShells() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");

        ShellToken.Recipient[] memory recipients = new ShellToken.Recipient[](2);
        recipients[0] = ShellToken.Recipient(user1, 100);
        recipients[1] = ShellToken.Recipient(user2, 200);

        vm.startPrank(admin);
        shellToken.mintBatchShells(recipients);
        vm.stopPrank();

        assertEq(shellToken.balanceOf(user1), 100);
        assertEq(shellToken.balanceOf(user2), 200);
    }

    function test_revert_mintBatchShells_notAdmin() public {
        address user = makeAddr("user");

        ShellToken.Recipient[] memory recipients = new ShellToken.Recipient[](1);
        recipients[0] = ShellToken.Recipient(user, 100);

        vm.startPrank(makeAddr("notAdmin"));
        vm.expectRevert("Not an admin");
        shellToken.mintBatchShells(recipients);
        vm.stopPrank();

        assertEq(shellToken.balanceOf(user), 0);
    }

    function test_deleteShells() public {
        address user = makeAddr("user");

        vm.startPrank(admin);
        shellToken.mintShells(user, 100);
        vm.stopPrank();

        assertEq(shellToken.balanceOf(user), 100);

        vm.startPrank(admin);
        shellToken.deleteShells(user, 100);
        vm.stopPrank();

        assertEq(shellToken.balanceOf(user), 0);
    }

    function test_revert_deleteShells_notAdmin() public {
        address user = makeAddr("user");

        vm.startPrank(admin);
        shellToken.mintShells(user, 100);
        vm.stopPrank();

        assertEq(shellToken.balanceOf(user), 100);

        vm.startPrank(makeAddr("notAdmin"));
        vm.expectRevert("Not an admin");
        shellToken.deleteShells(user, 100);
        vm.stopPrank();

        assertEq(shellToken.balanceOf(user), 100);
    }

    function test_revert_transfer_notAllowed() public {
        address user = makeAddr("user");
        address to = makeAddr("to");

        vm.startPrank(admin);
        shellToken.mintShells(user, 100);
        vm.stopPrank();

        assertEq(shellToken.balanceOf(user), 100);

        vm.startPrank(user);
        vm.expectRevert("Not allowed to transfer");
        shellToken.transfer(to, 100);
        vm.stopPrank();

        assertEq(shellToken.balanceOf(user), 100);
        assertEq(shellToken.balanceOf(to), 0);
    }

    function test_transfer_allowed() public {
        address user = makeAddr("user");
        address to = makeAddr("to");
        
        vm.prank(admin);
        shellToken.mintShells(user, 100);

        assertEq(shellToken.balanceOf(user), 100);

        vm.prank(owner);
        shellToken.updateAllowedToTransfer(user, true);

        vm.prank(user);
        shellToken.transfer(to, 100);

        assertEq(shellToken.balanceOf(user), 0);
        assertEq(shellToken.balanceOf(to), 100);
    }

    function test_revert_transferFrom_notAllowed() public {
        address user = makeAddr("user");
        address to = makeAddr("to");

        vm.startPrank(admin);
        shellToken.mintShells(user, 100);
        vm.stopPrank();

        assertEq(shellToken.balanceOf(user), 100);

        vm.prank(user);
        shellToken.approve(address(this), 100);
        
        vm.expectRevert("Not allowed to transfer");
        shellToken.transferFrom(user, to, 100);

        assertEq(shellToken.balanceOf(user), 100);
        assertEq(shellToken.balanceOf(to), 0);
    }

    function test_transferFrom_allowed() public {
        address user = makeAddr("user");
        address to = makeAddr("to");
        
        vm.prank(admin);
        shellToken.mintShells(user, 100);

        assertEq(shellToken.balanceOf(user), 100);

        vm.prank(owner);
        shellToken.updateAllowedToTransfer(user, true);

        vm.prank(user);
        shellToken.approve(address(this), 100);

        shellToken.transferFrom(user, to, 100);

        assertEq(shellToken.balanceOf(user), 0);
        assertEq(shellToken.balanceOf(to), 100);
    }
}