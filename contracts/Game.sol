// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./interfaces/IGameFactory.sol";

contract Game is Initializable, ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    uint256 constant public MAX_BPS = 10000;

    uint256 public id;
    uint256 public creatorFee;
    uint256 public platformFee;
    uint256 public minDeposit;
    uint256 public maxDeposit;
    address public creator;
    IGameFactory public factory;

    mapping(bytes32 => address) private requests;
    mapping(bytes32 => bool) private isJackpotRequest;
    mapping(bytes32 => string) private betIds;

    event RequestFulfilled(bytes32 reqId, uint256 value);
    event RequestRejected(bytes32 reqId, uint256 value);
    event Deposit(address sender, uint256 gameId, uint256 value);
    event Withdraw(address sender, uint256 gameId, uint256 value, string betId);
    event JackpotWithdraw(address sender, uint256 gameId, uint256 value, string betId);

    constructor() {}

    function initialize(uint256 _id, address _creator, uint256 _creatorFee, uint256 _minDeposit, uint256 _maxDeposit) external initializer onlyOwner {
        _transferOwnership(msg.sender);
        factory = IGameFactory(msg.sender);
        id = _id;
        creator = _creator;
        creatorFee = _creatorFee / 2;
        platformFee = _creatorFee / 2;
        setChainlinkOracle(factory.chainlinkOracle());
        setChainlinkToken(factory.chainlinkToken());
        minDeposit = _minDeposit;
        maxDeposit = _maxDeposit;
    }

    function deposit() external payable {
        require(msg.value >= minDeposit && msg.value <= maxDeposit, "Invalid deposit amount");
        address sender = msg.sender;
        emit Deposit(sender, id, msg.value);
    }

    function requestWithdraw(string memory betId) public {
        address sender = msg.sender;
        Chainlink.Request memory req = buildChainlinkRequest(
            factory.jobId(),
            address(this),
            this.fulfillRequest.selector
        );
        req.add(
            "get",
            string(abi.encodePacked(factory.baseURI(), factory.endpoint(), "?gameId=", id, "&wallet=", addressToString(sender), "&betId=", betId))
        );
        req.add("path", "data,amount");
        req.addInt("times", 10**18);

        factory.requestLink();
        bytes32 reqId = sendChainlinkRequest(req, factory.chainlinkFee());

        betIds[reqId] = betId;
        requests[reqId] = msg.sender;
    }

    function requestJackpotWithdraw(string memory betId) public {
        address sender = msg.sender;
        Chainlink.Request memory req = buildChainlinkRequest(
            factory.jobId(),
            address(this),
            this.fulfillRequest.selector
        );
        req.add(
            "get",
            string(abi.encodePacked(factory.baseURI(), factory.endpoint(), "?gameId=", id, "&wallet=", addressToString(sender), "&betId=", betId))
        );
        req.add("path", "data,amount");
        req.addInt("times", 10**18);

        factory.requestLink();
        bytes32 reqId = sendChainlinkRequest(req, factory.chainlinkFee());

        requests[reqId] = msg.sender;
        betIds[reqId] = betId;
        isJackpotRequest[reqId] = true;
    }

    function fulfillRequest(
        bytes32 _requestId,
        uint256 amount
    ) public recordChainlinkFulfillment(_requestId) {
        if (payable(address(this)).balance < amount || amount <= 0) {
            emit RequestRejected(_requestId, amount);
        } else {
            uint256 platformFeeAmount = (amount * platformFee) / MAX_BPS;
            uint256 creatorFeeAmount = (amount * creatorFee) / MAX_BPS;

            payable(creator).transfer(creatorFeeAmount);
            payable(factory.owner()).transfer(platformFeeAmount);
            payable(requests[_requestId]).transfer(amount - (platformFeeAmount + creatorFeeAmount));

            if (isJackpotRequest[_requestId]) {
                emit JackpotWithdraw(requests[_requestId], id, amount, betIds[_requestId]);
            } else {
                emit Withdraw(requests[_requestId], id, amount, betIds[_requestId]);
            }
            emit RequestFulfilled(_requestId, amount);
        }
    }

    function withdrawLink(address owner) public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(factory.chainlinkToken());
        require(
            link.transfer(owner, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function addressToString(address _address) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";

        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(value[i + 12] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(value[i + 12] & 0x0f))];
        }

        return string(str);
    }

}
