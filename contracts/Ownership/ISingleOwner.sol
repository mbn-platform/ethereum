pragma solidity 0.5.6;

import './IOwnable.sol';

contract ISingleOwner is IOwnable{
  function setOwner(address owner)
    public;
}
