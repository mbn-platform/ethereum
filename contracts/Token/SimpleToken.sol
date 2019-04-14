pragma solidity 0.5.6;

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

import './ISimpleToken.sol';

contract SimpleToken is IToken, ERC20 {
  string public name = 'SimpleToken';
  string public symbol = 'STKN';
  uint8 public decimals = 18;

  constructor(address _receiver)
    public
  {
    require(_receiver != address(0), 'receiver_req');

    super._mint(_receiver, 1000000000 * 10 ** 18);
  }
}
