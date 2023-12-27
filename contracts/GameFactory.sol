// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./interfaces/IGame.sol";

contract GameFactory is Ownable {

    uint256 constant public MAX_BPS = 10000;
    uint256 internal constant LINK_DIVISIBILITY = 10**18;

    IERC20 public paymentToken;
    address public master;
    address public chainlinkToken;
    address public chainlinkOracle;
    uint256 public gamesCount;
    uint256 public platformFee;
    uint256 public chainlinkFee;
    string public baseURI;
    string public endpoint;
    bytes32 public jobId;

    mapping(address => bool) public isGame;

    using Clones for address;

    event CreateGame(address contractAddress, uint256 id, uint256 initialDeposit, address creator, uint256 creatorFee);

    constructor(address _master, IERC20 _paymentToken, uint256 _platformFee, string memory _baseURI, string memory _endpoint, address _chainlinkToken, address _chainlinkOracle, bytes32 _jobId) {
        master = _master;
        paymentToken = _paymentToken;
        jobId = _jobId;
        chainlinkFee = (1 * LINK_DIVISIBILITY) / 10;
        platformFee = _platformFee;
        baseURI = _baseURI;
        endpoint = _endpoint;
        chainlinkToken = _chainlinkToken;
        chainlinkOracle = _chainlinkOracle;
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

        isGame[clone] = true;

        emit CreateGame(clone, gamesCount, initialDeposit - platformFeeValue, sender, creatorFee);
        gamesCount++;
    }

    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
    }

    function setMaster(address _master) external onlyOwner {
        master = _master;
    }

    function requestLink() external {
        require(isGame[msg.sender], "requestLink: not a game");
        paymentToken.transfer(msg.sender, chainlinkFee);
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkToken);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function withdrawLinkFromGame(IGame game) public onlyOwner {
        game.withdrawLink(owner());
    }


}
