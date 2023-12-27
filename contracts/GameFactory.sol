// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IGame.sol";

contract GameFactory is Ownable {

    uint256 constant public MAX_BPS = 10000;

    address public master;
    IERC20 public paymentToken;
    uint256 public gamesCount;
    uint256 public platformFee;

    using Clones for address;

    event CreateGame(address contractAddress, uint256 id, uint256 initialDeposit, address creator, uint256 creatorFee);

    constructor(address _master, IERC20 _paymentToken, uint256 _platformFee) {
        master = _master;
        paymentToken = _paymentToken;
    }

    function setPaymentToken(IERC20 _paymentToken) external onlyOwner {
        paymentToken = _paymentToken;
    }

    function createGame(uint256 initialDeposit, uint256 creatorFee) external {
        address sender = msg.sender;
        address clone = master.clone();

        uint256 platformFeeValue = initialDeposit * platformFee / MAX_BPS;

        paymentToken.transferFrom(sender, owner(), platformFeeValue);
        paymentToken.transferFrom(sender, clone, initialDeposit - platformFeeValue);

        IGame(clone).initialize(gamesCount, sender, creatorFee);

        emit CreateGame(clone, gamesCount, initialDeposit - platformFeeValue, sender, creatorFee);
        gamesCount++;
    }

    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
    }

    function setMaster(address _master) external onlyOwner {
        master = _master;
    }


}
