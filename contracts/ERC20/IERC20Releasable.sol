pragma solidity 0.5.6;

contract IERC20Releasable {
  uint public releaseDate;
  bool public isReleased;
  function release() public;
}
