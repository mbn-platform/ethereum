pragma solidity 0.5.6;

import './IOwnable.sol';

contract ManyOwners is IOwnable {
  mapping(address => bool) private owners_;

  constructor()
    internal
  {}

  event OwnerAdded(address indexed owner);
  event OwnerRemoved(address indexed owner);

  modifier ownerOnly() {
    require(owners_[msg.sender], 'owner_access');
    _;
  }

  function _isOwner(address _sender)
    internal
    view
    returns(bool)
  {
    return owners_[_sender];
  }

  function isOwner(address _sender)
    public
    view
    returns(bool)
  {
    return _isOwner(_sender);
  }

  function addOwner(address _owner)
    public
    ownerOnly
  {
    require(_owner != address(0), 'owner_req');

    _addOwner(_owner);
  }

  function _addOwner(address _owner)
    internal
  {
    owners_[_owner] = true;

    emit OwnerAdded(_owner);
  }

  function removeOwner(address _owner)
    public
    ownerOnly
  {
    require(_owner != address(0), 'owner_req');
    require(owners_[_owner], 'owner_exists');

    _removeOwner(_owner);
  }

  function _removeOwner(address _owner)
    internal
  {
    owners_[_owner] = false;

    emit OwnerRemoved(_owner);
  }
}
