pragma solidity 0.5.6;

import 'openzeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

import '../Ownership/SingleOwner.sol';
import '../Token/IToken.sol';
import './IDistribution.sol';

contract Distribution is IDistribution, SingleOwner {
  using SafeMath for uint256;

  // ERC20 basic token contract being held
  IToken public token;

  // Contract stakeHolders
  mapping(address => bool) private stakeHolders_;
  // Available to stakeHolder
  mapping(address => uint256) private available_;
  mapping(address => uint256) private distributed_;

  // ### Token related variables

  // Maximum token supply which could be created via Presale process
  uint256 public maxSupply;
  // Tokens reserved by stakeHolders
  uint256 public reserved;
  // Timestamp when token release is enabled
  uint256 private releaseTime_;

  constructor(
    address _owner,
    address _token,
    uint256 _releaseTime,
    uint256 _unlockTime,
    uint256 _maxSupply
  )
    public
    SingleOwner(_owner)
  {
    require(_token != address(0), 'token_req');
    require(_releaseTime > block.timestamp, 'timestamp_gt');
    require(_maxSupply > 0, 'maxSupply_gt');

    token = IToken(_token);
    owner_ = _owner;
    treasure_ = _treasure;
    releaseTime_ = _releaseTime;
    maxSupply = _maxSupply;
  }

  // Events
  event Transferred(address receiver, uint256 amount);
  event StackeHolderAdded(address stakeHolder);

  // Modifiers
  modifier ownerOrStackeHolderOnly() {
    require(_isOwner(owner) || _isStackeHolder(msg.sender), 'owner_or_stakeHolder_access');
    _;
  }

  modifier stakeHolderOnly() {
    require(_isStackeHolder(msg.sender), 'stakeHolder_access');
    _;
  }

  modifier notReleasedOnly() {
    require(releaseTime_ < block.timestamp, 'not_release_only');
    _;
  }

  // # StackeHolder methods

  function addStackeHolder(address _stakeHolder, uint256 _available)
    public
    ownerOnly
    notReleasedOnly
  {
    require(_stakeHolder != address(0), 'stakeHolder_req');
    require(stakeHolders_[_stakeHolder] == false, 'stakeHolder_not_exists');

    stakeHolders_[_stakeHolder] = true;
    available_[_stakeHolder] = _available;
    reserved = reserved.add(_available);

    require(reserved <= maxSupply, 'reserved_lte');

    emit StackeHolderAdded(_stakeHolder);
  }

  function isStackeHolder(address _who)
    public
    view
    returns(bool)
  {
    return _isStackeHolder(_who);
  }

  function _isStackeHolder(address _who)
    internal
    view
    returns(bool)
  {
    return stakeHolders_[msg.sender] == true;
  }

  function increaseAvailable(address _stakeHolder, uint256 _amount)
    public
    ownerOnly
    notReleasedOnly
  {
    require(stakeHolders_[_stakeHolder] == true, 'stakeHolder_is');

    available_[_stakeHolder] = available_[_stakeHolder].add(_amount);
    reserved = reserved.add(_amount);

    require(reserved < maxSupply, 'reserved_lt');
  }

  function getAvailable(address _stakeHolder)
    public
    view
    returns(uint256)
  {
    return available_[_stakeHolder];
  }

  function getDistributed(address _stakeHolder)
    public
    view
    returns(uint256)
  {
    return distributed_[_stakeHolder];
  }

  // # Token release methods

  // Anyone could call release method if the release date is arrived.
  function releaseToken()
    public
  {
    require(releaseTime_ > block.timestamp, 'release_arrived');
    token.release();
  }

  function finalizeDistribution()
    public
    ownerOnly
    notReleasedOnly
  {
    maxSupply = reserved;
  }

  function getReleaseTime()
    public
    view
    returns(uint256)
  {
    return releaseTime_;
  }

  // # ERC20 Methods
  function balanceOf(address _receiver)
    public
    view
    returns(uint256)
  {
    return token.balanceOf(_receiver).add(locked_[_receiver]);
  }

  function transferTokens(address _to, uint256 _tokens)
    public
    stakeHolderOnly
  {
    require(_to != address(0), 'to_req');
    require(_tokens > 0, 'tokens_gt');
    require(_tokens <= available_[msg.sender], 'tokens_lte');

    token.mint(_to, _tokens);

    available_[msg.sender] = available_[msg.sender].sub(amount);
    distributed_[msg.sender] = distributed_[msg.sender].add(_tokens);

    emit Transferred(_to, _tokens);
  }
}
