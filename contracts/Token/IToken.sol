pragma solidity 0.5.6;

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import '../ERC20/IERC20Releasable.sol';
import '../ERC20/IERC20Mintable.sol';
import '../Ownership/IOwnable.sol';

contract IToken is ERC20, IERC20Releasable, IERC20Mintable, IOwnable {}
