pragma solidity 0.5.6;

import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import './IERC20Swap.sol';

contract ERC20Swap is IERC20Swap {
  IERC20 public tokenLeft;
  IERC20 public tokenRight;
  uint public amountLeft;
  uint public amountRight;
  address public ownerLeft;
  address public ownerRight;
  uint public releaseDate;
  // Lock
  bool public isLocked;

  constructor(
    address _tokenLeft,
    address _tokenRight,
    uint _amountLeft,
    uint _amountRight,
    address _ownerLeft,
    address _ownerRight,
    uint _releaseDate
  )
    public
  {
    require(_tokenLeft != address(0), 'tokenLeft_req');
    require(_tokenRight != address(0), 'tokenRight_req');
    require(_amountLeft > 0, 'amountLeft_gt');
    require(_amountRight > 0, 'amountRight_gt');
    require(_addressLeft != address(0), 'addressLeft_req');
    require(_addressRight != address(0), 'addressRight_req');
    require(_releaseDate > now, 'releaseDate_gt');

    tokenLeft = _tokenLeft;
    tokenRight = _tokenRight;
    amountLeft = _amountLeft;
    amountRight = _amountRight;
    addressLeft = _addressLeft;
    addressRight = _addressRight;
  }

  modifier notLockedOnly()
  {
    _;
  }

  function deposit()
    public
    notLockedOnly
  {
    require(isLocked == false, 'locked_only');
    require(tokenLeft.allowance(ownerLeft, address(this)) >= amountLeft, 'tokenLeft_allowed');
    require(tokenRight.allowance(ownerRight, address(this)) >= amountRight, 'tokenRight_allowed');

    tokenLeft.transferFrom(_ownerFrom, address(this), _amountLeft);
    tokenRight.transferFrom(_ownerFrom, address(this), _amountRight);

    isLocked = true;
  }

  function receive()
    public
  {
    require(isLocked, 'isLocked');
    require(now >= _releaseDate, 'releaseDate');

    tokenLeft.transfer(ownerRight);
    tokenRight.transfer(ownerLeft);

    selfdestruct;
  }
}
