pragma solidity 0.5.6;

import './IOwnable.sol';

contract IMinions is IOwnable {
  function addMinion(address minion)
    public;

  function removeMinion(address minion)
    public;

  function _isMinion(address who)
    internal view returns(bool);
}
