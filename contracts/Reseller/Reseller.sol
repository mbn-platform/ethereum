pragma solidity 0.5.6;

import 'openzeppelin-solidity/contracts/math/Math.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

import '../Ownership/SingleOwner.sol';
import '../Distribution/IStagedDistribution.sol';

contract Reseller is SingleOwner {
  using Math for uint256;
  using SafeMath for uint256;

  struct State {
    uint256 balance;
    uint256 tokens;
    uint256 bonus;
    uint256 refBonus;
    uint256 lastIncome;
    uint256 extraBonus;
    bool hasRef;
  }

  // Token distribution
  IStagedDistribution public presale;
  // Contract owner
  address private owner_;
  // Accounts' total balances
  mapping(address => uint256) private balances_;
  // Bonuses received from referrals
  mapping(address => uint256) private bonuses_;
  // Incomes per user
  mapping(address => uint256[]) private incomes_;
  // Income dates per user
  mapping(address => uint256[]) private times_;
  // Last withdrawed income index
  mapping(address => uint256) private lastIncome_;
  // Refferencies
  mapping(address => address) private refs_;

  // Referal bonus is 7 %
  uint256 REFERAL_BONUS = 7;
  uint256 MAX_EXTRA_BONUS = 20;

  constructor(
    address _owner,
    address _presale
  )
    public
    SingleOwner(_owner)
  {
    require(_presale != address(0), 'presale_req');

    presale = IStagedDistribution(_presale);
  }

  function ()
    external
    payable
  {
    incomes_[msg.sender].push(msg.value);
    times_[msg.sender].push(block.timestamp);
    balances_[msg.sender] = balances_[msg.sender].add(msg.value);
  }

  event Transferred(address from, address to, address ref, uint256 balance, uint256 tokens, uint256 bonus);

  modifier ownerOnly() {
    require(msg.sender == owner_, 'owner_access');
    _;
  }

  event Filled(address receiver, uint256 amount);

  function fillBalance(address _to)
    public
    payable
  {
    fillBalance(_to, address(0));
  }

  function fillBalance(address _to, address _ref)
    public
    payable
  {
    require(_to != address(0), 'to_req');
    if (_ref != address(0) && refs_[_to] != _ref) {
      require(refs_[_to] == address(0), 'ref_mismatch');
      refs_[_to] = _ref;
    }
    _fillBalance(_to, msg.value);
    emit Filled(_to, msg.value);
  }

  function _fillBalance(address _to, uint256 _value)
    internal
  {
    incomes_[_to].push(_value);
    times_[_to].push(block.timestamp);
    balances_[_to] = balances_[_to].add(_value);
  }

  function getBalance(address _receiver)
    public
    view
    returns(uint256)
  {
    return balances_[_receiver];
  }

  function chargeback(address payable _receiver)
    public
    ownerOnly
  {
    uint256 balance = balances_[_receiver];
    require(balance > 0, 'balance_gt');

    balances_[_receiver] = 0;
    lastIncome_[_receiver] = incomes_[_receiver].length;

    _receiver.transfer(balance);
  }

  function getRef(address _sender)
    public
    view
    returns(address)
  {
    return refs_[_sender];
  }

  function getIncomesCount(address _sender)
    public
    view
    returns(uint256)
  {
    return incomes_[_sender].length;
  }

  function getLastIncome(address _sender)
    public
    view
    returns(uint256)
  {
    return lastIncome_[_sender];
  }

  function transferTokens(address _from, address _to, address _ref)
    public
  {
    transferTokens(_from, _to, _ref, 0);
  }

  function transferTokens(address _from, address _to, address _ref, uint256 _extraBonus)
    public
    ownerOnly
  {
    require(_from != address(0), 'from_req');
    require(_to != address(0), 'to_req');
    require(_extraBonus <= MAX_EXTRA_BONUS, 'extraBonus');

    _transferTokens(_from, _to, _ref, _extraBonus);
  }

  function _transferTokens(address _from, address _to, address _ref, uint256 _extraBonus)
    internal
  {
    require(_extraBonus < MAX_EXTRA_BONUS);

    State memory state = State(
      0,
      0,
      bonuses_[_from],
      0,
      lastIncome_[_from],
      _extraBonus,
      false
    );

    if (refs_[_from] != address(0)) {
      require(_ref == address(0) || refs_[_from] == _ref, 'ref_mismatch');
      state.hasRef = true;
      refs_[_from] = _ref;
    }
    else if (_ref != address(0)) {
      refs_[_from] = _ref;
      state.hasRef = true;
    }

    _calcIncomes(_from, state);

    lastIncome_[_from] = state.lastIncome;
    if (state.refBonus > 0) {
      bonuses_[_ref] = bonuses_[_ref].add(state.refBonus);
    }

    balances_[_from] = balances_[_from].sub(state.balance);

    uint256 half = state.bonus / 2;

    presale.transferTokens.value(state.balance)(_to, state.tokens + half, state.bonus - half);

    emit Transferred(_from, _to, _ref, state.balance, state.tokens, state.bonus);
  }

  function _calcIncomes(address _from, State memory _state)
    internal
    view
  {
    for (uint256 i = _state.lastIncome; i < getIncomesLength(_from); i++) {
      uint256 period = getPeriodByIndex(_from, i);
      (uint256 stage, bool exists) = presale.getStageByTime(period);

      if (! exists) {
        break;
      }

      _state.lastIncome = i;
      _state.balance = _state.balance.add(incomes_[_from][i]);

      _calculatePeriod(
        period, stage, getIncomeByIndex(_from, i), _state
      );
    }
  }

  function _calculatePeriod(
    uint _period,
    uint _stage,
    uint _income,
    State memory _state
  )
    internal
    view
  {

    uint256 amount = _income.div(presale.getRate(_period));
    _state.tokens = _state.tokens.add(amount);
    _state.bonus = _state.bonus.add(
      amount.mul(presale.getStageBonus(_stage).add(_state.extraBonus)).div(100)
    );

    if (_state.hasRef) {
      _state.refBonus = _state.refBonus.add(amount.mul(REFERAL_BONUS).div(100));
    }
  }

  function getPresaleStage(uint256 _period)
    internal
    view
    returns(uint256)
  {
    (uint256 stage, bool exists) = presale.getStageByTime(_period);

    require(exists, 'stage_missing');

    return stage;
  }

  function getPeriodByIndex(address _receiver, uint256 i)
    internal
    view
    returns(uint256)
  {
    return times_[_receiver][i];
  }

  function getIncomesLength(address _receiver)
    internal
    view
    returns(uint256)
  {
    return incomes_[_receiver].length;
  }

  function getIncomeByIndex(address _receiver, uint256 i)
    internal
    view
    returns(uint256)
  {
    return incomes_[_receiver][i];
  }
}
