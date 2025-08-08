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

    function test_setMultiplier() public {
        address activity = makeAddr("activity");

        vm.startPrank(owner);
        shellToken.setMultiplier(activity, 100);
        vm.stopPrank();
    }

    function test_revert_setMultiplier_notOwner() public {
        address activity = makeAddr("activity");
        address notOwner = makeAddr("notOwner");

        vm.startPrank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        shellToken.setMultiplier(activity, 100);
        vm.stopPrank();

        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, admin));
        shellToken.setMultiplier(activity, 100);
        vm.stopPrank();
    }

    function test_getMultipliers() public {
        address[] memory contracts = new address[](3);
        contracts[0] = makeAddr("activity1");
        contracts[1] = makeAddr("activity2");
        contracts[2] = makeAddr("activity3");

        vm.startPrank(owner);
        for (uint i; i < contracts.length; ) {
            shellToken.setMultiplier(contracts[i], 100 + i);
            unchecked { ++i; }
        }
        vm.stopPrank();

        ShellToken.Multiplier[] memory multipliers = shellToken.getMultipliers(contracts);
        assertEq(multipliers.length, contracts.length);
        for (uint i; i < multipliers.length; ) {
            assertEq(multipliers[i].activity, contracts[i]);
            assertEq(multipliers[i].multiplier, 100 + i);
            unchecked { ++i; }
        }
    }

    function test_setTotalMultiplier() public {
        // Default value
        assertEq(shellToken.totalMultiplier(), 10_000);

        vm.prank(owner);
        shellToken.setTotalMultiplier(9999);

        assertEq(shellToken.totalMultiplier(), 9999);
    }

    function test_revert_setTotalMultiplier_notOwner() public {
        address notOwner = makeAddr("notOwner");

        vm.startPrank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        shellToken.setTotalMultiplier(100);
        vm.stopPrank();

        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, admin));
        shellToken.setTotalMultiplier(100);
        vm.stopPrank();
    }
}