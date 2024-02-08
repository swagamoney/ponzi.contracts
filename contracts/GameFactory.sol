// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IGame.sol";

contract GameFactory is Ownable {

    address public master;
    uint256 public gamesCount;

    mapping(address => bool) public isGame;

    using Clones for address;

    event CreateGame(address contractAddress, uint256 id, uint256 initialDeposit, address creator, uint256 fee, string name, uint256 roi, uint256 maxDeposit, uint256 minDeposit, string file);

    constructor(address _master) {
        master = _master;
    }

    function createGame(uint256 fee, uint256 maxDeposit, uint256 minDeposit, uint256 roi, string memory file, string memory name) external payable {
        address sender = msg.sender;
        address clone = Clones.clone(master);

        IGame(clone).initialize{value: msg.value}(gamesCount, sender, fee, minDeposit, maxDeposit);

        isGame[clone] = true;

        emit CreateGame(clone, gamesCount, msg.value, sender, fee, name, roi, maxDeposit, minDeposit, file);
        gamesCount++;
    }

    function setMaster(address _master) external onlyOwner {
        master = _master;
    }

    receive() external payable {}


}
