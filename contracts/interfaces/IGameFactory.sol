// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IGameFactory {
    function paymentToken() external view returns (IERC20);
    function gamesCount() external view returns (uint256);
    function platformFee() external view returns (uint256);
    function owner() external view returns (address);
}
