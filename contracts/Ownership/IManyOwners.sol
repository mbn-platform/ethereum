pragma solidity 0.5.6;

import './IOwnable.sol';

contract IManyOwners is IOwnable {
  function addOwner(address owner)
    public;

  function removeOwner(address owner)
    public;
}
