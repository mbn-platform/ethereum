pragma solidity 0.5.6;

import './IToken.sol';
import '../Ownership/SingleOwner.sol';
import '../Access/Privileged.sol';

contract Token is IToken, SingleOwner, Privileged {
  string public name = 'Membrana';
  string public symbol = 'MBN';
  uint8 public decimals = 18;
  address public controller;
  bool public isReleased;

  constructor(address _owner)
    public
    SingleOwner(_owner)
  {}

  // Modifiers
  modifier releasedOnly() {
    require(isReleased, 'released_only');
    _;
  }

  modifier notReleasedOnly() {
    require(! isReleased, 'not_released_only');
    _;
  }

  modifier releasedOrPrivilegedOnly() {
    require(isReleased || isPrivileged(msg.sender), 'released_or_privileged_only');
    _;
  }

  // Methods

  function mint(address to, uint256 value)
    public
    ownerOnly
    notReleasedOnly
    returns (bool)
  {
    _mint(to, value);
    return true;
  }

  function transfer(address to, uint256 value)
    public
    releasedOrPrivilegedOnly
    returns (bool)
  {
    return super.transfer(to, value);
  }

  function transferFrom(address from,address to, uint256 value)
    public
    releasedOnly
    returns (bool)
  {
    return super.transferFrom(from, to, value);
  }

  function approve(address spender, uint256 value)
    public
    releasedOnly
    returns (bool)
  {
    return super.approve(spender, value);
  }

  function increaseAllowance(address spender, uint addedValue)
    public
    releasedOnly
    returns (bool success)
  {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(address spender, uint subtractedValue)
    public
    releasedOnly
    returns (bool success)
  {
    return super.decreaseAllowance(spender, subtractedValue);
  }

  function release()
    public
    ownerOnly
    notReleasedOnly
  {
    isReleased = true;
  }

  function setPrivileged(address _addr)
    public
    ownerOnly
  {
    _setPrivileged(_addr);
  }

  function setUnprivileged(address _addr)
    internal
    ownerOnly
  {
    _setUnprivileged(_addr);
  }
}
