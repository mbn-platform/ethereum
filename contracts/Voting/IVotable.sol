pragma solidity 0.5.6;

contract IVotable {
  function vote(uint256 value) public;
  function revoke(uint256 value) public;
  function votesOf(uint256 value) public view returns (uint256);
  function powerOf(address voter) public view returns (uint256);
  function isCompleted(uint256 value) public view returns (bool);
}
