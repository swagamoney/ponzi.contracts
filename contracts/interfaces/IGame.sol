interface IGame {
    function initialize(uint256 id, address creator, uint256 creatorFee) external;
    function withdrawLink(address owner) external;
}
