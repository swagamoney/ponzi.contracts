// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IGameFactory.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract Game is Initializable, ChainlinkClient {

    uint256 constant public MAX_BPS = 10000;

    uint256 public id;
    uint256 public creatorFee;
    address public creator;
    IGameFactory public factory;

    mapping(bytes32 => address) private requests;

    event RequestFulfilled(bytes32 reqId, uint256 value);
    event RequestRejected(bytes32 reqId, uint256 value);
    event Deposit(address sender, uint256 gameId, uint256 value);

    constructor() {}

    function initialize(uint256 _id, address _creator, uint256 _creatorFee) external initializer {
        factory = IGameFactory(msg.sender);
        id = _id;
        creator = _creator;
        creatorFee = _creatorFee;
    }

    function deposit(uint256 gameId, uint256 value) external {
        address sender = msg.sender;

        uint256 platformFeeValue = value * factory.platformFee() / MAX_BPS;
        uint256 creatorFeeValue = value * creatorFee / MAX_BPS;
        uint256 depositValue = value - (platformFeeValue + creatorFeeValue);

        token.transferFrom(sender, platformFeeValue, factory.owner());
        token.transferFrom(sender, creatorFeeValue, creator);
        token.transferFrom(sender, address(this), depositValue);

        emit Deposit(sender, gameId, depositValue);
    }



}
