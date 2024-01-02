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
    address public creator;
    IGameFactory public factory;

    mapping(bytes32 => address) private requests;

    event RequestFulfilled(bytes32 reqId, uint256 value);
    event RequestRejected(bytes32 reqId, uint256 value);
    event Deposit(address sender, uint256 gameId, uint256 value);
    event Withdraw(address sender, uint256 gameId, uint256 value);

    constructor() {}

    function initialize(uint256 _id, address _creator, uint256 _creatorFee) external initializer onlyOwner {
        _transferOwnership(msg.sender);
        factory = IGameFactory(msg.sender);
        id = _id;
        creator = _creator;
        creatorFee = _creatorFee;
        setChainlinkOracle(factory.chainlinkOracle());
        setChainlinkToken(factory.chainlinkToken());
    }

    function deposit(uint256 value) external {
        address sender = msg.sender;

        uint256 platformFeeValue = value * factory.platformFee() / MAX_BPS;
        uint256 creatorFeeValue = value * creatorFee / MAX_BPS;
        uint256 depositValue = value - (platformFeeValue + creatorFeeValue);

        factory.paymentToken().transferFrom(sender, factory.owner(), platformFeeValue);
        factory.paymentToken().transferFrom(sender, creator, creatorFeeValue);
        factory.paymentToken().transferFrom(sender, address(this), depositValue);

        emit Deposit(sender, id, depositValue);
    }

    function requestWithdraw() public {
        address sender = msg.sender;
        Chainlink.Request memory req = buildChainlinkRequest(
            factory.jobId(),
            address(this),
            this.fulfillRequest.selector
        );
        req.add(
            "get",
            string(abi.encodePacked(factory.baseURI(), factory.endpoint(), "?gameId=", id, "&wallet=", addressToString(sender)))
        );
        req.add("path", "data,amount");
        req.addInt("times", 10**18);

        factory.requestLink();
        bytes32 reqId = sendChainlinkRequest(req, factory.chainlinkFee());

        requests[reqId] = msg.sender;
    }

    function fulfillRequest(
        bytes32 _requestId,
        uint256 amount
    ) public recordChainlinkFulfillment(_requestId) {
        if (factory.paymentToken().balanceOf(address(this)) < amount || amount <= 0) {
            emit RequestRejected(_requestId, amount);
        } else {
            factory.paymentToken().transfer(requests[_requestId], amount);
            emit Withdraw(requests[_requestId], id, amount);
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
