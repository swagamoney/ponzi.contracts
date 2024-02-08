// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interfaces/IGameFactory.sol";
import "./EIP712Initializable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Game is Initializable, EIP712Initializable, Ownable {
    using Strings for uint256;

    string constant private SIGNING_DOMAIN = "GameContractDomain";
    string constant private SIGNATURE_VERSION = "1";

    uint256 constant public MAX_BPS = 10000;

    uint256 public id;
    uint256 public nonce;
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

    function initialize(uint256 _id, address _creator, uint256 _creatorFee, uint256 _minDeposit, uint256 _maxDeposit) external payable initializer {
        _transferOwnership(msg.sender);
        factory = IGameFactory(msg.sender);
        _initEip712(SIGNING_DOMAIN, SIGNATURE_VERSION);
        id = _id;
        creator = _creator;
        creatorFee = _creatorFee / 2;
        platformFee = _creatorFee / 2;
        minDeposit = _minDeposit;
        maxDeposit = _maxDeposit;
    }

    function deposit() external payable {
        require(msg.value >= minDeposit && msg.value <= maxDeposit, "Invalid deposit amount");
        address sender = msg.sender;
        emit Deposit(sender, id, msg.value);
    }

    function withdraw(bool isJackpot, string memory betId, uint256 amount, uint256 _nonce, bytes calldata signature) public {
        require(_nonce == nonce, "Invalid nonce");
        address recipient = msg.sender;

        bytes32 structHash = keccak256(abi.encode(
            keccak256("Claim(uint256 amount,uint256 nonce,address recipient)"),
            amount,
            _nonce,
            recipient
        ));

        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, signature);

        require(signer == factory.owner(), "Invalid signature");
        uint256 platformFeeAmount = (amount * platformFee) / MAX_BPS;
        uint256 creatorFeeAmount = (amount * creatorFee) / MAX_BPS;

        payable(creator).transfer(creatorFeeAmount);
        payable(factory.owner()).transfer(platformFeeAmount);
        payable(recipient).transfer(amount - (platformFeeAmount + creatorFeeAmount));

        nonce++;
        if (isJackpot) {
            emit JackpotWithdraw(recipient, id, amount, betId);
        } else {
            emit Withdraw(recipient, id, amount, betId);
        }
    }


    receive() external payable {}

}
