// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./interfaces/IGame.sol";

contract GameFactory is Ownable {

    uint256 internal constant LINK_DIVISIBILITY = 10**18;

    address public master;
    address public chainlinkToken;
    address public chainlinkOracle;
    uint256 public gamesCount;
    uint256 public chainlinkFee;
    string public baseURI;
    string public endpoint;
    bytes32 public jobId;

    mapping(address => bool) public isGame;

    using Clones for address;

    event CreateGame(address contractAddress, uint256 id, uint256 initialDeposit, address creator, uint256 fee, string name, uint256 roi, uint256 maxDeposit, uint256 minDeposit, string file);

    constructor(address _master, string memory _baseURI, string memory _endpoint, address _chainlinkToken, address _chainlinkOracle, bytes32 _jobId) {
        master = _master;
        jobId = _jobId;
        chainlinkFee = (1 * LINK_DIVISIBILITY) / 10;
        baseURI = _baseURI;
        endpoint = _endpoint;
        chainlinkToken = _chainlinkToken;
        chainlinkOracle = _chainlinkOracle;
    }

    function createGame(uint256 initialDeposit, uint256 fee, uint256 maxDeposit, uint256 minDeposit, uint256 roi, string memory file, string memory name) external payable {
        address sender = msg.sender;
        address clone = master.clone();

        payable(clone).transfer(msg.value);

        IGame(clone).initialize(gamesCount, sender, fee, minDeposit, maxDeposit);

        isGame[clone] = true;

        emit CreateGame(clone, gamesCount, initialDeposit, sender, fee, name, roi, maxDeposit, minDeposit, file);
        gamesCount++;
    }

    function setMaster(address _master) external onlyOwner {
        master = _master;
    }

    function requestLink() external {
        require(isGame[msg.sender], "requestLink: not a game");
        IERC20(chainlinkToken).transfer(msg.sender, chainlinkFee);
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkToken);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setEndpoint(string memory _endpoint) external onlyOwner {
        endpoint = _endpoint;
    }

    function withdrawLinkFromGame(IGame game) public onlyOwner {
        game.withdrawLink(owner());
    }


}
