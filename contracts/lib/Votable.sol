pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract Votable {
  using SafeMath for uint256;

  address owner;

  uint256 public totalVotes;

  uint256 public lastProposal;
  mapping(address => uint256) voters_;
  mapping(uint256 => uint256) private votes_;
  mapping(uint256 => bool) private completed_;
  mapping(uint256 => mapping(address => bool)) private status_;

  constructor(address _owner)
    internal
  {
    owner = _owner;
  }

  // Events
  event ProposalAdded(address voter, uint256 number);
  event VotesAdded(address voter, uint256 number, uint256 votes);
  event VotesRevoked(address voter, uint256 number, uint256 votes);

  // Modifiers
  modifier ownerOnly() {
    require(msg.sender == owner, 'owner_access');
    _;
  }

  modifier voterOnly() {
    require(voters_[msg.sender] > 0, 'voter_access');
    _;
  }

  modifier votable(uint256 _n) {
    require(completed_[_n] == false, 'completed_eq');
    require(_n > 0, 'n_gt');
    require(_n <= lastProposal, 'n_lte');
    require(isVotable(_n), 'isVotable');
    _;
  }

  function setOwner(address _owner)
    public
    ownerOnly
  {
    owner = _owner;
  }

  // Methods
  function addVoter(address _voter)
    public
    ownerOnly
  {
    addVoter(_voter, 1);
  }

  function addVoter(address _voter, uint256 _votes)
    public
    ownerOnly
  {
    require(_voter != address(0), 'voter_req');
    require(voters_[_voter] == 0, 'exists_not');
    require(_votes > 0, 'votes_gt');

    voters_[_voter] = _votes;
    totalVotes = totalVotes.add(_votes);
  }

  function removeVoter(address _voter)
    public
    ownerOnly
  {
    require(_voter != address(0), 'voter_req');
    require(voters_[_voter] != 0, 'exists_not');

    totalVotes = totalVotes.sub(voters_[_voter]);
    voters_[_voter] = 0;
  }

  function initVoting(uint256 _n)
    internal
  {
    require(_n > lastProposal, 'n_gt');
    require(votes_[_n] == 0, 'votes_eq');

    uint256 votes = voters_[msg.sender];
    status_[_n][msg.sender] = true;
    votes_[_n] = votes_[_n].add(votes);
    lastProposal = _n;

    emit ProposalAdded(msg.sender, _n);
    emit VotesAdded(msg.sender, _n, votes);
  }

  function vote(uint256 _n)
    public
    voterOnly
    votable(_n)
  {
    require(status_[_n][msg.sender] == false, 'status_eq');

    uint votes = voters_[msg.sender];
    votes_[_n] = votes_[_n].add(votes);

    emit VotesAdded(msg.sender, _n, votes);

    if (isAccepted(_n, votes_[_n])) {
      completed_[_n] = true;
      proposalAccepted(_n);
    }
    else {
      status_[_n][msg.sender] = true;
    }
  }

  function revoke(uint256 _n)
    public
    voterOnly
  {
    require(status_[_n][msg.sender] == true, 'status_ok');

    uint votes = voters_[msg.sender];
    votes_[_n] = votes_[_n].sub(votes);
    status_[_n][msg.sender] = false;

    emit VotesRevoked(msg.sender, _n, votes);
  }

  function votesOf(uint256 _n)
    public
    view
    returns(uint256)
  {
    return votes_[_n];
  }

  function isCompleted(uint256 _n)
    public
    view
    returns(bool)
  {
    return completed_[_n];
  }

  function powerOf(address _voter)
    public
    view
    returns(uint256)
  {
    return voters_[_voter];
  }

  function proposalAccepted(uint256 _n) internal;

  function isVotable(uint256 _n)
  internal
  view
  returns(bool);

  function isAccepted(uint256 _n, uint256 _votes)
    internal
    view
    returns(bool);
}
