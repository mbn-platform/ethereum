pragma solidity 0.5.6;

import './IOwnable.sol';

contract IManyMembers is IOwnable {
  function addMember(address minion)
    public;

  function removeMember(address minion)
    public;

  function _isMember(address who)
    internal view returns(bool);
}
