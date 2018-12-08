pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/math/Math.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

import './Distribution.sol';

contract Reseller {
  using Math for uint256;
  using SafeMath for uint256;

  // Token distribution
  Distribution public presale;
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
  mapping(address => uint256) private allowedIncome_;

  // Referal bonus is 7 %
  uint256 REFERAL_BONUS = 7;
  uint256 MAX_EXTRA_BONUS = 20;

  constructor(
    address _presale,
    address _owner
  )
    public
  {
    require(_presale != address(0), 'presale_req');
    require(_owner != address(0), 'owner_req');

    presale = Distribution(_presale);
    owner_ = _owner;
  }

  function ()
    public
    payable
  {
    incomes_[msg.sender].push(msg.value);
    times_[msg.sender].push(block.timestamp);
    balances_[msg.sender].add(msg.value);
  }

  modifier ownerOnly() {
    require(msg.sender == owner_, 'owner_access');
    _;
  }

  function chargeback(address _receiver)
    public
    ownerOnly
  {
    uint256 balance = balances_[_receiver];
    require(balance > 0, 'balance_gt');

    balances_[_receiver] = 0;
    allowedIncome_[_receiver] = incomes_[_receiver].length;

    _receiver.transfer(balance);
  }

  function transferTokens(address _from, address _to, address _ref, uint256 _extraBonus)
    public
    ownerOnly
  {
    require(_from != address(0), 'from_req');
    require(_to != address(0), 'to_req');
    require(_extraBonus <= MAX_EXTRA_BONUS, 'extraBonus');

    uint256 balance = balances_[_from];

    // Total tokens
    uint256 tokens = 0;
    // Receiver's bonus
    uint256 bonus = bonuses_[_from];
    // Beneficiar's bonus
    uint256 refBonus = 0;
    // Extra bonus
    bool hasRef = _ref != address(0);

    for (uint256 i = allowedIncome_[_from]; i < getIncomesLength(_from); i++) {
      uint256 period = getPeriodByIndex(_from, i);
      (tokens, bonus, refBonus) = _calculatePeriod(
        period, getIncomeByIndex(_from, i), _extraBonus, tokens, bonus, refBonus, hasRef
      );
    }

    allowedIncome_[_from] = getIncomesLength(_from);
    if (refBonus > 0) {
      bonuses_[_ref] = bonuses_[_ref].add(refBonus);
    }

    balances_[_from] = 0;
    bonuses[_from] = 0;

    _transferTokens(_to, balance, tokens, bonus);
  }

  function _transferTokens(address _to, uint256 _value, uint256 _tokens, uint256 _bonus)
    internal
  {
    uint256 half = _bonus / 2;

    presale.transferTokens.value(_value)(_to, _tokens + half, _bonus - half);
  }

  function _calculatePeriod(
    uint period,
    uint income,
    uint extraBonus,
    uint tokens,
    uint bonus,
    uint refBonus,
    bool hasRef
  )
    internal
    view
    returns(uint, uint, uint)
  {
    uint256 stage = getPresaleStage(period);

    uint256 amount = income.div(presale.getRate(period));
    tokens = tokens.add(amount);
    bonus = bonus.add(
      amount.mul(presale.getStageBonus(stage).add(extraBonus)).div(100)
    );

    if (hasRef) {
      refBonus = refBonus.add(amount.mul(REFERAL_BONUS).div(100));
    }

    return (tokens, bonus, refBonus);
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
