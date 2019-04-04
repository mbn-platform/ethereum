pragma solidity 0.5.6;

import './Swap.sol';

contract SwapFactory {
  event SwapCreated(address at, address sideA, address sideB);

  address[] all;
  mapping(address => bool) children;
  mapping(address => address[]) private contracts;

  function createSwap(
    address tokenA,
    address outputA,
    uint amountA,
    address tokenB,
    address outputB,
    uint amountB,
    uint payoutStart,
    uint payoutEnd,
    uint payoutCount
  )
  public
  returns(address)
  {
    address cx = address(new Swap(
      tokenA, outputA, amountA, tokenB, outputB, amountB, payoutStart, payoutEnd, payoutCount
    ));
    contracts[tokenA].push(cx);
    contracts[tokenB].push(cx);
    children[cx] = true;
    all.push(cx);

    emit SwapCreated(cx, tokenA, tokenB);

    return cx;
  }

  function countSwaps()
    public
    view
    returns(uint)
  {
    return all.length;
  }

  function getSwapByIndex(uint _index)
    public
    view
    returns(address)
  {
    return all[_index];
  }

  function countTokenSwaps(address token)
    public
    view
    returns(uint)
  {
    return contracts[token].length;
  }

  function getTokenSwapByIndex(address token, uint i)
    public
    view
    returns(address)
  {
    return contracts[token][i];
  }
}
