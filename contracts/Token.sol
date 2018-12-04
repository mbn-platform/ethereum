pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract Token is ERC20 {
  string public name = 'Membrana';
  string public symbol = 'MBN';
  uint8 public decimals = 18;
  address public controller;
  bool public isReleased;

  constructor(address _controller)
    public
  {
    require(_controller != address(0));

    controller = _controller;
  }

  event Released();

  // Modifiers

  modifier controllerOnly() {
    require(msg.sender == controller);
    _;
  }

  modifier releasedOnly() {
    require(isReleased);
    _;
  }

  modifier notReleasedOnly() {
    require(! isReleased);
    _;
  }

  // Methods

  function mint(address to, uint256 value)
    public
    controllerOnly
    returns (bool)
  {
    _mint(to, value);
    return true;
  }

  function transfer(address to, uint256 value)
    public
    releasedOnly
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

  function release() public controllerOnly notReleasedOnly {
    isReleased = true;
    emit Released();
  }
}
