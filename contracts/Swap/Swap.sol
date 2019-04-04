pragma solidity 0.5.6;

import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';

contract Swap {
  address tokenA;
  address outputA;
  uint remainA;

  address tokenB;
  address outputB;
  uint remainB;

  uint payoutStart;
  uint payoutEnd;
  uint payoutPeriod;

  uint nextPayoutA;
  uint payoutCountA;
  uint nextPayoutB;
  uint payoutCountB;

  constructor(
    address _tokenA,
    address _outputA,
    uint _amountA,
    address _tokenB,
    address _outputB,
    uint _amountB,
    uint _payoutStart,
    uint _payoutEnd,
    uint _payoutCount
  )
  public
  {
    tokenA = _tokenA;
    outputA = _outputA;
    remainA = _amountA;

    tokenB = _tokenB;
    outputB = _outputB;
    remainB = _amountB;

    payoutPeriod = (_payoutStart - _payoutEnd) / _payoutCount;

    payoutStart = _payoutStart;
    payoutEnd = _payoutEnd;

    payoutCountA = _payoutCount;
    payoutCountB = _payoutCount;

    nextPayoutA = _payoutStart;
    nextPayoutB = _payoutStart;
  }

  function()
    external
  {
    revert('not_available');
  }

  modifier onlyA() {
    require(msg.sender == outputA, 'onlyA');
    _;
  }

  modifier onlyB() {
    require(msg.sender == outputB, 'onlyB');
    _;
  }

  function chargebackA()
    public
    onlyA
  {
    uint tokenAmount = IERC20(tokenA).balanceOf(address(this));

    require(tokenAmount > remainA);

    IERC20(tokenA).transfer(outputA, tokenAmount - remainA);
  }

  function chargebackAllA()
    external
    onlyA
  {
    uint depositB = IERC20(tokenB).balanceOf(address(this));
    require(depositB < remainB, 'depositB_lt');

    uint tokenAmount = IERC20(tokenA).balanceOf(address(this));
    IERC20(tokenA).transfer(outputA, tokenAmount);
  }

  function chargebackB()
    external
    onlyB
  {
    uint tokenAmount = IERC20(tokenB).balanceOf(address(this));

    require(tokenAmount > remainB);

    IERC20(tokenB).transfer(outputB, tokenAmount - remainB);
  }

  function chargebackAllB()
    onlyB
    external
  {
    uint depositA = IERC20(tokenA).balanceOf(address(this));
    require(depositA < remainA, 'depositA_lt');

    uint tokenAmount = IERC20(tokenB).balanceOf(address(this));
    IERC20(tokenB).transfer(outputB, tokenAmount);
  }

  function withdrawToA()
    external
  {
    require(nextPayoutA < now);
    require(payoutCountA > 0);

    uint count = (now - nextPayoutA) / payoutPeriod + 1;

    if (count >= payoutCountA) {
      IERC20(tokenB).transfer(outputA, remainA);
      payoutCountA = 0;
    }
    else {
      IERC20(tokenB).transfer(outputA, remainA - (remainA / payoutCountA) * count);
      payoutCountA -= count;
      nextPayoutA = nextPayoutA + payoutPeriod * count;
    }
  }

  function withdrawToB()
    external
  {
    require(nextPayoutB < now);
    require(payoutCountB > 0);

    uint count = (now - nextPayoutB) / payoutPeriod + 1;

    if (count >= payoutCountB) {
      IERC20(tokenA).transfer(outputB, remainB);
    }
    else {
      IERC20(tokenA).transfer(outputB, remainB - (remainB / payoutCountB) * count);
      payoutCountB -= count;
      nextPayoutB = nextPayoutB + payoutPeriod * count;
    }
  }

  function close()
    external
  {
    // All payouts are made
    require(remainA == 0, 'remainA_zero');
    require(remainB == 0, 'remainB_zero');
    // All tokens withdrawn
    require(IERC20(tokenA).balanceOf(address(this)) == 0, 'tokenA_empty');
    require(IERC20(tokenB).balanceOf(address(this)) == 0, 'tokenB_empty');

    selfdestruct(address(0));
  }
}
