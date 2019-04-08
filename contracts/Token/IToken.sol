pragma solidity 0.5.6;

import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import '../ERC20/IERC20Releasable.sol';
import '../Ownership/IOwnable.sol';

contract IToken is IERC20, IERC20Releasable, IOwnable {}
