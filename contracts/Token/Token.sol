pragma solidity 0.5.6;

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

import './IToken.sol';
import '../Ownership/SingleOwner.sol';
import '../Access/Privileged.sol';

contract Token is IToken, ERC20, SingleOwner, Privileged {
  string public name = 'Membrana';
  string public symbol = 'MBN';
  uint8 public decimals = 18;
  bool public isReleased;
  uint public releaseDate;

  constructor(address _owner)
    public
    SingleOwner(_owner)
  {
    super._mint(owner, 1000000000 * 10^18);
  }

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

  function transfer(address to, uint256 value)
    public
    releasedOrPrivilegedOnly
    returns (bool)
  {
    return super.transfer(to, value);
  }

  function transferFrom(address from, address to, uint256 value)
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
    releaseDate = now;
  }

  function setPrivileged(address _addr)
    public
    ownerOnly
  {
    _setPrivileged(_addr);
  }

  function setUnprivileged(address _addr)
    public
    ownerOnly
  {
    _setUnprivileged(_addr);
  }
}
