pragma solidity 0.4.25;

import 'openzeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

import './IToken.sol';

contract Distribution {
  using SafeMath for uint256;

  uint256 MAX_BONUS = 90;

  // ERC20 basic token contract being held
  IToken public token;

  // Contract owner address
  address private owner_;
  // Contract treasure
  address private treasure_;
  // Contract resellers
  mapping(address => bool) private resellers_;
  // Available to reseller
  mapping(address => uint256) private available_;
  // Available to reseller
  mapping(address => uint256) private locked_;
  // Exchange rates
  mapping(uint256 => uint256) rates_;
  // Rate periods
  uint256[] ratePeriods_;

  // ### Token related variables

  // Maximum token supply which could be created via Presale process
  uint256 public maxSupply;
  // Tokens reserved by presellers
  uint256 public reserved;
  // Timestamp when token release is enabled
  uint256 private releaseTime_;
  // Time when bonus lock is disabled
  uint256 private unlockTime_;

  // ### State
  // Size of personal bonus
  mapping(address => address[]) locks_;
  // Stages list
  uint256[] stagesStart_;
  uint256[] stagesEnd_;
  uint256[] stagesBonus_;

  constructor(
    address _owner,
    address _token,
    address _treasure,
    uint256 _releaseTime,
    uint256 _unlockTime,
    uint256 _maxSupply,
    uint256 _rate
  )
    public
  {
    require(_owner != address(0), 'owner_req');
    require(_token != address(0), 'token_req');
    require(_treasure != address(0), 'treasure_req');
    require(_releaseTime > block.timestamp, 'timestamp_gt');
    require(_unlockTime >= _releaseTime, 'unlock_gte');
    require(_maxSupply > 0, 'maxSupply_gt');
    require(_rate > 0, 'rate_gt');

    token = IToken(_token);
    owner_ = _owner;
    treasure_ = _treasure;
    releaseTime_ = _releaseTime;
    unlockTime_ = _unlockTime;
    maxSupply = _maxSupply;
    _setRate(_rate, getMidnight() - 1 days);
  }

  // Events
  event Locked(address receiver, uint256 amount, address lock);
  event Transferred(address receiver, uint256 amount);
  event Received(address sender, uint256 amount);

  event ResellerAdded(address reseller);
  event ResellerRemoved(address reseller);

  // Modifiers
  modifier ownerOnly() {
    require(msg.sender == owner_, 'owner_access');
    _;
  }

  modifier ownerOrResellerOnly() {
    require(msg.sender == owner_ || resellers_[msg.sender] == true, 'owner_or_reseller_access');
    _;
  }

  modifier resellerOnly() {
    require(resellers_[msg.sender] == true, 'reseller_access');
    _;
  }

  // Methods
  // Management methods
  function addReseller(address _reseller, uint256 _available)
    public
    ownerOnly
  {
    require(_reseller != address(0), 'to_req');
    require(resellers_[_reseller] == false, 'exists');

    resellers_[_reseller] = true;
    emit ResellerAdded(_reseller);
    available_[_reseller] = _available;
    reserved = reserved.add(_available);

    require(reserved <= maxSupply, 'reserved_lte');
  }

  function removeReseller(address _reseller)
    public
    ownerOnly
  {
    require(_reseller != address(0), 'to_req');
    require(resellers_[_reseller] == true, 'not_exists');

    resellers_[_reseller] = false;
    emit ResellerRemoved(_reseller);
    reserved = reserved.sub(available_[_reseller]);
    available_[_reseller] = 0;
  }

  function isReseller(address _addr)
    public
    view
    returns(bool)
  {
    return resellers_[_addr];
  }

  function availableToReseller(address _reseller)
    public
    view
    returns(uint256)
  {
    return available_[_reseller];
  }

  function increaseAvailable(address _reseller, uint256 _amount)
    public
    ownerOnly
  {
    require(resellers_[_reseller] == true, 'reseller_is');

    available_[_reseller] = available_[_reseller].add(_amount);
    reserved = reserved.add(_amount);

    require(reserved < maxSupply, 'reserved_lt');
  }

  function decreaseAvailable(address _reseller, uint256 _amount)
    public
    ownerOnly
  {
    require(resellers_[_reseller] == true, 'reseller_is');

    available_[_reseller] = available_[_reseller].sub(_amount);
    reserved = reserved.sub(_amount);
  }

  function getAvailable(address _reseller)
    public
    view
    returns(uint256)
  {
    return available_[_reseller];
  }

  function setNextRate(uint256 _rate)
    public
    ownerOnly
  {
    require(_rate > 0, 'rate_gt');

    _setRate(_rate, getMidnight());
  }

  function _setRate(uint256 _rate, uint256 _time)
    internal
  {
    if (ratePeriods_.length > 0) {
      require(_time > ratePeriods_[ratePeriods_.length - 1], 'time_gt');
    }

    ratePeriods_.push(_time);
    rates_[_time] = _rate;
  }

  function getCurrentRate()
    public
    view
    returns(uint256)
  {
    return _getRate(now);
  }

  function getRate(uint256 _time)
    public
    view
    returns(uint256)
  {
    require(_time > getLastPeriod(), 'time_gt');
    return _getRate(_time);
  }

  function _getRate(uint256 _time)
    internal
    view
    returns(uint256)
  {
    (uint256 i, bool exists) = _getRateIndex(_time, ratePeriods_.length);

    if (exists) {
      return rates_[ratePeriods_[i]];
    }
    else {
      return 0;
    }
  }

  function _getRateIndex(uint256 _time, uint256 _length)
    internal
    view
    returns(uint256, bool)
  {
    for (uint256 i = _length; i > 0; i--) {
      uint n = i - 1;
      uint256 period = ratePeriods_[n];

      if (period < _time) {
        return (n, true);
      }
    }

    return (0, false);
  }

  function getLastPeriod()
    public
    view
    returns(uint256)
  {
    if (ratePeriods_.length > 0) {
      return ratePeriods_[ratePeriods_.length - 1];
    }
    else {
      return 0;
    }
  }

  function getActiveStageIndex()
    public
    view
    returns(uint256,bool)
  {
    return _getStageByTime(now, stagesStart_.length);
  }

  function getStageByTime(uint256 _time)
    public
    view
    returns(uint256,bool)
  {
    return _getStageByTime(_time, stagesStart_.length);
  }

  function getStageByTime(uint256 _time, uint256 _initial)
    public
    view
    returns(uint256,bool)
  {
    return _getStageByTime(_time, _initial);
  }

  function _getStageByTime(uint256 _time, uint256 _initial)
    internal
    view
    returns(uint256,bool)
  {
    for (uint n = _initial; n > 0; n--) {
      uint256 i = n - 1;

      uint256 start = stagesStart_[i];
      uint256 end = stagesEnd_[i];
      if (start < _time) {
        if (end > _time) {
          return (i, true);
        }
        else {
          return (0, false);
        }
      }
    }
    return (0, false);
  }

  function addStage(uint256 _start, uint256 _end, uint256 _bonus)
    public
    ownerOnly
    returns(uint256)
  {
    require(_start < _end, 'start_ls');
    require(_end <= releaseTime_, 'end_lte');
    require(_bonus <= MAX_BONUS, 'bonus_lte');

    bool exists = stagesStart_.length > 0;
    if (exists) {
      uint256 last = stagesStart_.length - 1;
      require(_start >= stagesEnd_[last], 'start_gte');
    }

    stagesStart_.push(_start);
    stagesEnd_.push(_end);
    stagesBonus_.push(_bonus);

    return stagesStart_.length - 1;
  }

  function getStagesLength()
    public
    view
    returns(uint256)
  {
    return stagesStart_.length;
  }

  function getStageStart(uint256 i)
    public
    view
    returns(uint256)
  {
    return stagesStart_[i];
  }

  function getStageEnd(uint256 i)
    public
    view
    returns(uint256)
  {
    return stagesEnd_[i];
  }

  function getStageBonus(uint256 i)
    public
    view
    returns(uint256)
  {
    return stagesBonus_[i];
  }

  function getLocksCount(address _to)
    public
    view
    returns(uint256)
  {
    return locks_[_to].length;
  }

  function getLock(address _to, uint256 n)
    public
    view
    returns(address)
  {
    return locks_[_to][n];
  }

  function getLockedBalance(address _to)
    public
    view
    returns(uint256)
  {
    return locked_[_to];
  }

  // Anyone could call release method if the release date is arrived.
  function releaseToken()
    public
  {
    require(releaseTime_ > block.timestamp, 'release_arrived');

    token.release();
  }

  function getReleaseTime()
    public
    view
    returns(uint256)
  {
    return releaseTime_;
  }

  function getUnlockTime()
    public
    view
    returns(uint256)
  {
    return unlockTime_;
  }

  // Get next midnight in milliseconds
  function getMidnight()
      internal
      view
      returns(uint256)
  {
      uint256 tomorrow = now + 1 days;
      uint256 remain = tomorrow % 1 days;
      return tomorrow - remain;
  }

  function balanceOf(address _receiver)
    public
    view
    returns(uint256)
  {
    return token.balanceOf(_receiver).add(locked_[_receiver]);
  }

  event Log(string label);

  function transferTokens(address _to, uint256 _tokens, uint256 _locked)
    public
    resellerOnly
    payable
    returns(uint256)
  {
    uint256 amount = _tokens.add(_locked);

    require(_to != address(0), 'to_req');
    require(amount <= available_[msg.sender], 'not_available');

    require(treasure_.send(msg.value), 'transfer');

    // Send locked bonuses to timelock contract
    if (_locked > 0) {
      address lock = address(new TokenTimelock(token, _to, unlockTime_));
      token.mint(lock, _locked);
      locks_[_to].push(lock);
      locked_[_to] = locked_[_to].add(_locked);

      emit Locked(_to, _locked, lock);
    }

    if (_tokens > 0) {
      token.mint(_to, _tokens);
      emit Transferred(_to, _tokens);
    }

    available_[msg.sender] = available_[msg.sender].sub(amount);
    return amount;
  }
}
