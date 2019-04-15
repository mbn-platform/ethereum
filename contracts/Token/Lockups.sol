pragma solidity 0.5.6;

import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';
import '../ERC20/IERC20Releasable.sol';
import '../Ownership/SingleOwner.sol';

contract Lockups is SingleOwner {
  address public token;
  uint public lockPeriod;
  mapping(address => uint) public amounts;
  uint public withdrawnAmount;
  uint public totalAmount;

  constructor(address _owner, address _token, uint256 _lockPeriod)
    public
    SingleOwner(_owner)
  {
    require(_token != address(0), 'token_req');
    require(_lockPeriod > 0, 'lockPeriod_gt');

    token = _token;
    lockPeriod = _lockPeriod;
  }

  function increase(address _receiver, uint _amount)
    public
    ownerOnly
  {
    require(_receiver != address(0), 'receiver_req');
    require(withdrawnAmount == 0, 'withdrawnAmount_zero');

    amounts[_receiver] += _amount;
    totalAmount += _amount;
  }

  function balanceOf(address _receiver)
    public
    view
    returns(uint)
  {
    return amounts[_receiver];
  }

  function withdraw(address _receiver)
    public
  {
    require(_receiver != address(0), 'receiver_req');

    uint amount = amounts[_receiver];

    require(amount > 0, 'amount_gt');

    if (withdrawnAmount == 0) {
      IERC20Releasable releasable = IERC20Releasable(token);

      require(releasable.isReleased(), 'released');
      require(releasable.releaseDate() + lockPeriod < now, 'lockPeriod_expired');
    }

    amounts[_receiver] = 0;
    totalAmount -= amount;
    withdrawnAmount += amount;

    IERC20(token).transfer(_receiver, amount);
  }
}
