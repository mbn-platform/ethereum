pragma solidity 0.5.6;

import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';

contract IERC20Swap {
  // Transfer allowed tokens
  function deposit() public;
  // Receive swapped tokens
  function receive() public;
}
