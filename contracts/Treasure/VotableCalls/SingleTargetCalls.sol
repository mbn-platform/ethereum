pragma solidity 0.5.6;

import '../../Voting/Votable.sol';
import '../../CollectableCalls/CollectableCalls.sol';

contract SingleTargetCalls is CollectableCalls, Votable {
  address private target_;
  uint[] private values_;
  bytes[] private callData_;
  bytes32[] private expectations_;
  bool[] private hasExpectations_;

  constructor(address _target)
    public
  {
    require(_target != address(0), 'target_req');

    // Shift index
    target_ = _target;
    callData_.push("");
    values_.push(0);
    expectations_.push(0);
    hasExpectations_.push(false);
  }

  // Own methods

  /// Propose call without expected result
  function proposeCall(uint _value, bytes memory _data)
    public
    voterOnly
    nonReentrant
    returns(uint256)
  {
    return _proposeCall(_value, _data, false, 0);
  }

  function proposeCall(uint _value, bytes memory _data, bytes32 _expectation)
    public
    voterOnly
    nonReentrant
    returns(uint256)
  {
    return _proposeCall(_value, _data, true, _expectation);
  }

  /// Propose call with expected result. Expected result is a keccak256 number.
  function _proposeCall(
    uint _value,
    bytes memory _data,
    bool _hasExpectation,
    bytes32 _expectation
  )
    internal
    returns(uint256)
  {
    callData_.push(_data);
    values_.push(_value);
    expectations_.push(_expectation);
    hasExpectations_.push(_hasExpectation);

    uint256 n = callData_.length;

    super.initVoting(n);
    return n;
  }

  // Votable contract methods
  function applyProposal(uint256 _n)
    internal
  {
    super.makeCall(_n);
  }

  function isAccepted(uint256, uint256 _votes, uint256 _totalPower)
    internal
    view
    returns(bool)
  {
    return _votes >= _totalPower / 2 + 1;
  }

  // ContractManager methods

  function _getTarget(uint _n)
    internal
    view
    returns(address)
  {
    return target_;
  }

  function _getCallData(uint _n)
    internal
    view
    returns(bytes memory)
  {
    return callData_[_n];
  }

  function _hasExpectation(uint _n)
    internal
    view
    returns(bool)
  {
    return hasExpectations_[_n];
  }

  function _getExpectation(uint _n)
    internal
    view
    returns(bytes32)
  {
    return expectations_[_n];
  }

  function _getValue(uint _n)
    internal
    view
    returns(uint)
  {
    return values_[_n];
  }
}
