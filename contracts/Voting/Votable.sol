pragma solidity 0.5.6;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract Votable {
  using SafeMath for uint256;

  uint256 public totalPower;

  uint256 public lastProposal;
  mapping(address => uint256) votePower_;
  mapping(uint256 => uint256) private votes_;
  mapping(uint256 => bool) private completed_;
  mapping(uint256 => mapping(address => uint256)) private givenVotes_;

  // Events
  event ProposalAdded(address voter, uint256 number);
  event VotesAdded(address voter, uint256 number, uint256 votes);
  event VotesRevoked(address voter, uint256 number, uint256 votes);

  // Modifiers
  modifier voterOnly() {
    require(votePower_[msg.sender] > 0, 'voter_access');
    _;
  }

  modifier votableOnly(uint256 _n) {
    require(completed_[_n] == false, 'completed_eq');
    require(_n > 0, 'n_gt');
    require(_n <= lastProposal, 'n_lte');
    require(isVotable(_n), 'isVotable');
    _;
  }

  modifier ownerOnly() {
    require(_isOwner(msg.sender), 'owner_access');
    _;
  }

  function _isOwner(address) internal view returns(bool);

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
    require(votePower_[_voter] == 0, 'exists_not');
    require(_votes > 0, 'votes_gt');

    votePower_[_voter] = _votes;
    totalPower = totalPower.add(_votes);
  }

  function removeVoter(address _voter)
    public
    ownerOnly
  {
    require(_voter != address(0), 'voter_req');
    require(votePower_[_voter] != 0, 'exists_not');

    totalPower = totalPower.sub(votePower_[_voter]);
    votePower_[_voter] = 0;
  }

  function initVoting(uint256 _n)
    internal
  {
    require(_n > lastProposal, 'n_gt');
    require(votes_[_n] == 0, 'votes_eq');

    lastProposal = _n;

    emit ProposalAdded(msg.sender, _n);
    _vote(_n);
  }

  function vote(uint256 _n)
    public
    voterOnly
    votableOnly(_n)
  {
    require(givenVotes_[_n][msg.sender] == 0, 'givenVotes_eq');
    require(completed_[_n] == false);

    _vote(_n);
  }

  function _vote(uint256 _n)
    internal
  {
    uint votes = votePower_[msg.sender];
    votes_[_n] = votes_[_n].add(votes);

    emit VotesAdded(msg.sender, _n, votes);

    givenVotes_[_n][msg.sender] = votes;

    if (isAccepted(_n, votes_[_n], totalPower)) {
      completed_[_n] = true;
      proposalAccepted(_n);
    }
  }

  function revoke(uint256 _n)
    public
    voterOnly
    votableOnly(_n)
  {
    require(givenVotes_[_n][msg.sender] > 0, 'givenVotes_ok');

    uint votes = givenVotes_[_n][msg.sender];
    votes_[_n] = votes_[_n].sub(votes);
    givenVotes_[_n][msg.sender] = 0;

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
    return votePower_[_voter];
  }

  function proposalAccepted(uint256 _n) internal;

  /// Determine if proposal still votable or not. In treasurer proposals
  /// has no any limitation thus each vote is votable until it completes.
  function isVotable(uint256)
    internal
    view
    returns(bool)
  {
    return true;
  }

  function isAccepted(uint256 _n, uint256 _votes, uint256 _totalPower)
    internal
    view
    returns(bool);
}
