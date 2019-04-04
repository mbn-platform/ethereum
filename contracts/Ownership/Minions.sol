pragma solidity 0.5.6;

import './IMinions.sol';

// Need to be ownable
contract Minions is IMinions {
  mapping(address => bool) private minions_;

  event MinionAdded(address indexed minion);
  event MinionRemoved(address indexed minion);

  modifier minionOnly() {
    require(minions_[msg.sender], 'minion_access');
    _;
  }

  modifier ownerOnly() {
    require(_isOwner(msg.sender), 'owner_access');
    _;
  }

  modifier ownerOrMinionOnly() {
    require(_isOwner(msg.sender) || _isMinion(msg.sender), 'owner_or_minion_access');
    _;
  }

  function _isMinion(address _sender)
    internal
    view
    returns(bool)
  {
    return minions_[_sender];
  }

  function addMinion(address _minion)
    public
    ownerOnly
  {
    require(_minion != address(0), 'minion_req');

    minions_[_minion] = true;

    emit MinionAdded(_minion);
  }

  function removeMinion(address _minion)
    public
    ownerOnly
  {
    require(_minion != address(0), 'minion_req');

    minions_[_minion] = false;

    emit MinionRemoved(_minion);
  }
}
