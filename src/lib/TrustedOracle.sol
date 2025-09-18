// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TrustedOracle is Ownable {
    uint price;
    bool isSet;

    constructor(address owner)
        Ownable(owner)
    {}

    function setPrice(uint value) external onlyOwner {
        price = value;
        isSet = true;
    }

    function unsetPrice() external onlyOwner {
        isSet = false;
    }

    function read() external view returns(uint, bool) {
        return (price, isSet);
    }

    function readPrice() external view returns(uint) {
        return price;
    }
}