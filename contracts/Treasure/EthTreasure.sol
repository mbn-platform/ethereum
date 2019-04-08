pragma solidity 0.5.6;

import '../Voting/Votable.sol';
import '../Ownership/SingleOwner.sol';

contract EthTreasure is Votable, SingleOwner {
  struct Proposal {
    address payable to;
    uint256 amount;
  }

  Proposal[] private proposals_;

  constructor(address _owner)
    public
    payable
    SingleOwner(_owner)
  {}

  // Fallback
  function ()
    external
    payable
  {
    require(msg.data.length == 0, 'data_empty'); // No external calls
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
    require(proposal.amount <= address(this).balance, 'amount_enough');

    proposal.to.transfer(proposal.amount);

    emit Transferred(proposal.to, proposal.amount);
  }
}
