// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract CloneMock {
    address public clone;

    function deploy(address target) public {
        clone = Clones.clone(target);
    }
}
