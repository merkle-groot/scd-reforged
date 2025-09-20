// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.13;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Token is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(
        string memory name, 
        string memory symbol,
        address owner
    ) 
    ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }
}

contract TokenFactory {
    function deployToken(
        string memory name, 
        string memory symbol,
        address initialOwner
    ) external returns (Token) {
        // Todo(merkle-groot): maybe make this create2?
        return new Token(name, symbol, initialOwner);
    }
}