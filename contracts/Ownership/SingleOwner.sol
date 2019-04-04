pragma solidity 0.5.6;

import './IOwnable.sol';

contract SingleOwner is IOwnable {
  address public owner;

  constructor(
    address _owner
  )
    internal
  {
    require(_owner != address(0), 'owner_req');
    owner = _owner;

    emit OwnershipTransferred(address(0), owner);
  }

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier ownerOnly() {
    require(msg.sender == owner, 'owner_access');
    _;
  }

  function _isOwner(address _sender)
    internal
    view
    returns(bool)
  {
    return owner == _sender;
  }

  function isOwner(address _sender)
    public
    view
    returns(bool)
  {
    return _isOwner(_sender);
  }

  function setOwner(address _owner)
    public
    ownerOnly
  {
    address prevOwner = owner;
    owner = _owner;

    emit OwnershipTransferred(owner, prevOwner);
  }
}
