pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract Treasure {
  using SafeMath for uint256;

  mapping(address => bool) status_;
  address[] private participants_;
  uint256 public quorum;
  bool private isFinalized_;

  mapping(address => uint256) private amounts_;
  mapping(address => uint256) private votes_;
  mapping(address => mapping(address => bool)) private votesStatus_;

  constructor(uint256 _quorum)
    public
    payable
  {
    require(_quorum > 0);

    quorum = _quorum;
  }

  function () external payable {
    require(msg.data.length == 0); // No external calls
  }

  // Events
  event Transferred(address receiver, uint256 amount);
  event VotingStarted(address receiver, uint256 amount);
  event VotingEnded(address receiver, uint256 amount);
  event VotedUp(address party, address receiver, uint256 amount);
  event VotedDown(address party, address receiver, uint256 amount);

  // Modifiers
  modifier partyOnly() {
    require(status_[msg.sender] == true, 'party_only');
    _;
  }

  modifier notFinalizedOnly() {
    require(isFinalized_ == false, 'finalized_only');
    _;
  }

  // Methods
  function addParty(address _party)
    public
    notFinalizedOnly
  {
    require(_party != address(0), 'party_req');
    require(status_[_party] == false, 'party_not');

    status_[_party] = true;
    participants_.push(_party);
  }

  function initTransfer(address _to, uint256 _amount)
    public
    partyOnly
  {
    require(_to != address(0), 'tonull');
    require(amounts_[_to] == 0, 'exists');
    require(_amount > 0, 'amount');

    amounts_[_to] = _amount;
    votesStatus_[_to][msg.sender] = true;
    votes_[_to] = 1;

    emit VotingStarted(_to, _amount);
  }

  function voteUp(address _to, uint256 _amount)
    public
    partyOnly
  {
    require(amounts_[_to] > 0, 'amount_empty');
    require(votesStatus_[_to][msg.sender] == false, 'status_true');
    require(amounts_[_to] == _amount, 'amount');

    votes_[_to] = votes_[_to].add(1);

    emit VotedUp(msg.sender, _to, _amount);

    if (votes_[_to] == quorum) {
      processTransfer(_to);
    }
    else {
      votesStatus_[_to][msg.sender] = true;
    }
  }

  function voteDown(address _to, uint256 _amount)
    public
    partyOnly
  {
    require(amounts_[_to] > 0, 'amout_req');
    require(votesStatus_[_to][msg.sender] == true, 'status_ok');
    require(amounts_[_to] == _amount, 'amout_eq');

    votes_[_to] = votes_[_to].sub(1);
    votesStatus_[_to][msg.sender] = false;

    emit VotedDown(msg.sender, _to, _amount);

    if (votes_[_to] == 0) {
      amounts_[_to] = 0;

      emit VotingEnded(_to, _amount);
    }
  }

  function votesOf(address _to, uint256 _amount)
    public
    view
    returns(uint256)
  {
    if (amounts_[_to] != _amount) {
      return 0;
    }

    return votes_[_to];
  }

  function processTransfer(address _to)
    internal
  {
    uint256 amount = amounts_[_to];

    amounts_[_to] = 0;
    votes_[_to] = 0;

    for (uint256 i = 0; i < participants_.length; i++) {
      votesStatus_[_to][participants_[i]] = false;
    }

    _to.transfer(amount);

    emit Transferred(_to, amount);
  }

  function finalize()
    public
  {
    isFinalized_ = true;
  }
}
