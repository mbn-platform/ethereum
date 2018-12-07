pragma solidity ^0.4.24;

import './lib/Votable.sol';

contract Treasure is Votable {
  struct Proposal {
    address to;
    uint256 amount;
  }

  Proposal[] public proposals;

  constructor(address _owner)
    public
    payable
    Votable(_owner)
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

  // Methodds
  function addProposal(address _to, uint256 _amount)
    public
    voterOnly
    returns(uint256)
  {
    proposals.push(Proposal(_to, _amount));
    uint256 n = proposals.length;

    initVoting(n);
    return n;
  }

  /// Determine if proposal still votable or not. In treasurer proposals
  /// has no any limitation thus each vote is votable until it completes.
  function isVotable(uint256)
    internal
    view
    returns(bool)
  {
    return true;
  }

  function isAccepted(uint256, uint256 _votes)
    internal
    view
    returns(bool)
  {
    return _votes >= totalVotes / 2 + 1;
  }

  function proposalAccepted(uint256 _n)
    internal
  {
    Proposal storage proposal = proposals[_n - 1];

    proposal.to.transfer(proposal.amount);

    emit Transferred(proposal.to, proposal.amount);
  }
}
