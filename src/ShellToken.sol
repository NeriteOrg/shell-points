// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract ShellToken is ERC20, Ownable {

    mapping(address => bool) public allowedToTransfer;

    constructor() ERC20("ShellToken", "SHELL") Ownable(msg.sender) {
    }

    function mintShells(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function deleteShells(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (allowedToTransfer[msg.sender]) {
            return super.transfer(to, amount);
        }
        return false;
    }

    function updateAllowedToTransfer(address user, bool allowed) public onlyOwner {
        allowedToTransfer[user] = allowed;
    }
}

