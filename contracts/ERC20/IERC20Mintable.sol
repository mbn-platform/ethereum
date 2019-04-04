pragma solidity 0.5.6;

contract IERC20Mintable {
  function mint(address to, uint256 value) public returns (bool);
}
