pragma solidity 0.5.6;

import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';

import '../Voting/Votable.sol';
import '../Ownership/SingleOwner.sol';

contract Erc20Treasure is Votable, SingleOwner {
  struct Proposal {
    address to;
    uint256 amount;
  }

  IERC20 public token;

  Proposal[] private proposals_;

  constructor(address _owner, address _token)
    public
    SingleOwner(_owner)
  {
    require(_token != address(0), 'token_req');
    token = IERC20(_token);
  }

  // Events
  event Transferred(address receiver, uint256 amount);

  // Methods
  function proposeTransfer(address payable _to, uint256 _amount)
    public
    voterOnly
    returns(uint256)
  {
    proposals_.push(Proposal(_to, _amount));
    uint256 n = proposals_.length;

    super.initVoting(n);
    return n;
  }

  function isAccepted(uint256, uint256 _votes, uint256 _totalPower)
    internal
    view
    returns(bool)
  {
    return _votes >= _totalPower / 2 + 1;
  }

  function applyProposal(uint256 _n)
    internal
  {
    Proposal storage proposal = proposals_[_n - 1];
    require(proposal.amount < address(this).balance, 'amount_enough');

    require(token.transfer(proposal.to, proposal.amount), 'transferred');

    emit Transferred(proposal.to, proposal.amount);
  }
}
