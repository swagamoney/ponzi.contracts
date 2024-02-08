interface IGame {
    function initialize(uint256 id, address creator, uint256 creatorFee, uint256 minDeposit, uint256 maxDeposit) external payable;
    function withdrawLink(address owner) external;
}
