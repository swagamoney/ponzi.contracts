// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IGameFactory {
    function gamesCount() external view returns (uint256);
    function owner() external view returns (address);
    function chainlinkFee() external view returns (uint256);
    function chainlinkToken() external view returns (address);
    function chainlinkOracle() external view returns (address);
    function baseURI() external view returns (string memory);
    function endpoint() external view returns (string memory);
    function jackpotEndpoint() external view returns (string memory);
    function jobId() external view returns (bytes32);
    function requestLink() external;
}
