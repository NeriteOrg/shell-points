// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract ShellToken is ERC20, Ownable {

    struct Recipient {
        address to;
        uint256 amount;
    }

    mapping(address => bool) public isAdmin;

    // address of activity -> multiplier
    // Activities are the contract addresses of Trove Managers, Stability Pools, LP tokens, etc.
    mapping(address => uint) public multiplier; //percentage out of 100

    mapping(address => bool) public allowedToTransfer;

    constructor() ERC20("Nerite Shell Points", "SHELL") Ownable(msg.sender) {}

    function mintShells(address to, uint256 amount) public {
        require(isAdmin[msg.sender], "Not an admin");
        _mint(to, amount);
    }

    function mintBatchShells(Recipient[] calldata recipients) public {
        require(isAdmin[msg.sender], "Not an admin");
        for (uint i; i < recipients.length; ) {
            _mint(recipients[i].to, recipients[i].amount);
            unchecked { ++i; }
        }
    }

    function deleteShells(address from, uint256 amount) public {
        require(isAdmin[msg.sender], "Not an admin");
        _burn(from, amount);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (!allowedToTransfer[msg.sender]) {
            revert("Not allowed to transfer");
        }
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (!allowedToTransfer[from]) {
            revert("Not allowed to transfer");
        }
        return super.transferFrom(from, to, amount);
    }

    //////////////////////////
    // ONLY OWNER FUNCTIONS //
    //////////////////////////

    function updateAllowedToTransfer(address user, bool allowed) public onlyOwner {
        allowedToTransfer[user] = allowed;
    }

    function updateIsAdmin(address user, bool _isAdmin) public onlyOwner {
        isAdmin[user] = _isAdmin;
    }
}

