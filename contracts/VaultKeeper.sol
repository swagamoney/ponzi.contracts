//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract VaultKeeper is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    string private baseURI;
    string private endpoint;

    bytes32 private jobId;
    uint256 private fee;

    IERC20 private token;

    mapping(bytes32 => address) private requests;

    event RequestFulfilled(bytes32 reqId, uint256 value);
    event RequestRejected(bytes32 reqId, uint256 value);
    event Deposit(address sender, uint256 gameId, uint256 value);

    constructor(string memory _baseURI, IERC20 _token, address _chainlinkToken, address _chainlinkOracle, bytes32 _jobId, string memory _endpoint) ConfirmedOwner(msg.sender) {
        setChainlinkToken(_chainlinkToken);
        setChainlinkOracle(_chainlinkOracle);
        jobId = _jobId;
        fee = (1 * LINK_DIVISIBILITY) / 10;
        baseURI = _baseURI;
        token = _token;
        endpoint = _endpoint;
    }

    function deposit(uint256 gameId, uint256 value) external {
        address sender = msg.sender;
        token.transferFrom(sender, address(this), value);
        emit Deposit(sender, gameId, value);
    }

    function requestWithdraw() public {
        address sender = msg.sender;
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillRequest.selector
        );
        req.add(
            "get",
            string(abi.encodePacked(baseURI, endpoint, addressToString(sender)))
        );
        req.add("path", "data,amount");
        req.addInt("times", 10**18);
        bytes32 reqId = sendChainlinkRequest(req, fee);

        requests[reqId] = msg.sender;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function withdrawAdmin(address token) external onlyOwner {
        IERC20(token).transferFrom(address(this), msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function fulfillRequest(
        bytes32 _requestId,
        uint256 amount
    ) public recordChainlinkFulfillment(_requestId) {
        if (token.balanceOf(address(this)) < amount || amount <= 0) {
            emit RequestRejected(_requestId, amount);
        } else {
            token.transfer(requests[_requestId], amount);
            emit RequestFulfilled(_requestId, amount);
        }
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
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