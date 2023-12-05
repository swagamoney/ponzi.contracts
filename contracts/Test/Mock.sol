// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20('test', 'test') {
        _mint(msg.sender, 1000000000000 * 10**18);
    }
}